//
//  NamecoinImportResolver.swift
//  Nos
//
//  Resolves the `import` item of a Namecoin Domain Name Object,
//  recursively merging values from the imported names into the
//  importing object before the caller extracts fields like `nostr`.
//
//  Reference: https://github.com/namecoin/proposals/blob/master/ifa-0001.md
//  (§"import" and §"map").
//
//  The 520-byte per-name limit on Namecoin makes apex `d/<name>`
//  records crowded. ifa-0001 §"import" lets a name delegate shared
//  blocks (like the `nostr.names` directory) into a sibling name —
//  conventionally `dd/<name>` — via an `"import"` key. Without
//  import-chain handling, NIP-05 lookups against records that use
//  this pattern silently fail: the resolver sees the apex value,
//  finds no `nostr` field, and returns nil.
//

import Foundation

/// Fetches the raw JSON value string for a Namecoin name.
/// Returns nil if the name does not exist, is expired, or could
/// not be fetched. Failures are absorbed by the caller; a returned
/// value of nil is treated as the empty object.
public typealias NamecoinValueFetcher = @Sendable (_ namecoinName: String) async -> String?

/// Expands ifa-0001 `import` directives on a Namecoin Domain Name
/// Object value.
public enum NamecoinImportResolver {
    /// The minimum recursion depth ifa-0001 requires implementations to support.
    public static let defaultMaxDepth: Int = 4

    /// Expand all `import` items in `root` (and recursively in imported
    /// objects) up to `maxDepth` levels deep, returning a single merged
    /// object with no `import` key.
    ///
    /// The merged object preserves the importing object's items unchanged;
    /// imported items only fill in keys the importing object did not declare
    /// (including keys whose value is `NSNull` — those remain suppressed).
    ///
    /// If `root` has no `import` key, it is returned unchanged. Records
    /// without `import` pay zero extra I/O cost.
    public static func expandImports(
        root: [String: Any],
        maxDepth: Int = defaultMaxDepth,
        fetcher: NamecoinValueFetcher
    ) async -> [String: Any] {
        var visited = Set<String>()
        return await expandRecursive(
            obj: root,
            fetcher: fetcher,
            budgetRemaining: maxDepth,
            visited: &visited
        )
    }

    // MARK: - Internals

    private static func expandRecursive(
        obj: [String: Any],
        fetcher: NamecoinValueFetcher,
        budgetRemaining: Int,
        visited: inout Set<String>
    ) async -> [String: Any] {
        guard let importItem = obj["import"] else { return obj }
        guard let operations = parseImportItem(importItem) else { return removeImportKey(obj) }
        if operations.isEmpty || budgetRemaining <= 0 { return removeImportKey(obj) }

        // Walk imports left-to-right. The spec is silent on multiple-import
        // precedence; we follow the common-sense rule that LATER imports
        // override EARLIER ones in the same array (otherwise listing two
        // libraries would silently ignore the second). The whole
        // accumulator still loses to the importing object on top of it.
        var accumulator: [String: Any] = [:]
        for op in operations {
            let visitKey = visitKeyFor(op)
            if !visited.insert(visitKey).inserted { continue } // cycle or dup
            defer { visited.remove(visitKey) }

            let importedRaw = await fetcher(op.name)
            guard let raw = importedRaw, let importedRoot = tryParseObject(raw) else { continue }
            guard let selectorView = applySelector(root: importedRoot, selector: op.selector) else { continue }
            let expanded = await expandRecursive(
                obj: selectorView,
                fetcher: fetcher,
                budgetRemaining: budgetRemaining - 1,
                visited: &visited
            )
            accumulator = mergeImporterWins(importer: expanded, imported: accumulator)
        }

        // Finally merge the importing object on top, removing its `import` key.
        let withoutImport = removeImportKey(obj)
        return mergeImporterWins(importer: withoutImport, imported: accumulator)
    }

    /// Merge two objects with importer-wins semantics: every key in
    /// `importer` stays as-is (including `NSNull` values, which suppress
    /// the imported counterpart per ifa-0001); keys present only in
    /// `imported` are added. Shallow per spec.
    private static func mergeImporterWins(
        importer: [String: Any],
        imported: [String: Any]
    ) -> [String: Any] {
        if imported.isEmpty { return importer }
        if importer.isEmpty { return imported }
        var out = imported
        for (k, v) in importer {
            out[k] = v
        }
        return out
    }

    /// Walk the imported object's `map` tree to the node addressed by
    /// `selector` (DNS dotted, e.g. `"relay"`, `"a.b.c"`). Empty selector
    /// returns `root` unchanged.
    ///
    /// Resolution rules per ifa-0001 §"map":
    ///   - Exact label match wins.
    ///   - Wildcard `*` matches any single label.
    ///   - Empty key `""` is the default for the current level when no
    ///     other match applies.
    ///   - A non-object child terminates the walk with nil.
    private static func applySelector(
        root: [String: Any],
        selector: String
    ) -> [String: Any]? {
        if selector.isEmpty { return root }

        // Selector is DNS-dotted: leftmost label is the most-specific.
        // The `map` tree is rooted at the parent and nests inwards
        // toward the leaf, so we walk labels right-to-left (the
        // rightmost label is the immediate child of the parent's `map`).
        let labels = selector
            .split(separator: ".", omittingEmptySubsequences: true)
            .map(String.init)
            .reversed()
        if labels.isEmpty { return root }

        var current: [String: Any] = root
        for label in labels {
            guard let map = current["map"] as? [String: Any] else { return nil }
            if let child = map[label] as? [String: Any] {
                current = child
            } else if let star = map["*"] as? [String: Any] {
                current = star
            } else if let def = map[""] as? [String: Any] {
                current = def
            } else {
                return nil
            }
        }
        return current
    }

    private static func tryParseObject(_ rawJson: String) -> [String: Any]? {
        guard let data = rawJson.data(using: .utf8) else { return nil }
        // .allowFragments mirrors NamecoinResolver.tryParseJSON.
        guard
            let obj = try? JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
        else { return nil }
        return obj
    }

    private static func removeImportKey(_ obj: [String: Any]) -> [String: Any] {
        guard obj["import"] != nil else { return obj }
        var out = obj
        out.removeValue(forKey: "import")
        return out
    }

    private static func visitKeyFor(_ op: ImportOp) -> String {
        "\(op.name)|\(op.selector)"
    }

    /// Parse the value of an `import` item into a flat list of `ImportOp`.
    /// Returns nil if the value is malformed.
    ///
    /// Accepted shapes (in order of preference):
    ///   - canonical: `[ ["d/foo"], ["d/bar","sub"] ]`
    ///   - shorthand string: `"d/foo"` → one op with no selector
    ///   - shorthand single-array: `["d/foo"]` → one op with no selector
    ///   - shorthand pair-array: `["d/foo","sub"]` → one op with selector
    ///
    /// Anything else is treated as malformed and the import is skipped.
    private static func parseImportItem(_ item: Any) -> [ImportOp]? {
        // Shorthand: bare string.
        if let s = item as? String {
            let trimmed = s.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return nil }
            return [ImportOp(name: trimmed, selector: "")]
        }
        // Array shapes.
        guard let arr = item as? [Any] else { return nil }
        if arr.isEmpty { return [] }

        // Distinguish: array-of-arrays (canonical) vs array-of-strings (shorthand).
        let firstIsArray = arr.first is [Any]
        if firstIsArray {
            return arr.compactMap { entry -> ImportOp? in
                guard let inner = entry as? [Any] else { return nil }
                return opFromArray(inner)
            }
        }
        // Shorthand: ["name"] or ["name","selector"]. All elements must be
        // strings; anything else makes the whole item malformed.
        guard let op = opFromArray(arr) else { return nil }
        return [op]
    }

    private static func opFromArray(_ arr: [Any]) -> ImportOp? {
        if arr.isEmpty { return nil }
        guard let rawName = arr[0] as? String else { return nil }
        let name = rawName.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { return nil }
        let selector: String
        if arr.count >= 2 {
            guard let rawSel = arr[1] as? String else { return nil }
            selector = rawSel.trimmingCharacters(in: .whitespaces)
        } else {
            selector = ""
        }
        // Trailing dot is forbidden by spec; treat as malformed → no selector.
        if selector.hasSuffix(".") { return nil }
        return ImportOp(name: name, selector: selector)
    }

    private struct ImportOp {
        let name: String
        /// DNS dotted, may be empty. Preserved as written.
        let selector: String
    }
}
