# CashuSwift Package Dependency Fix

## Issue
The build was failing with:
```
Dependencies could not be resolved because no versions of 'cashuswift' match the requirement 0.1.0..<1.0.0
```

## Root Cause
The CashuSwift repository doesn't have tagged versions (no 0.1.0 release). The package was configured to look for version 0.1.0 which doesn't exist.

## Fix Applied
Updated `/root/repo/Nos.xcodeproj/project.pbxproj` to use the main branch instead of a version:

```diff
requirement = {
-    kind = upToNextMajorVersion;
-    minimumVersion = 0.1.0;
+    branch = main;
+    kind = branch;
};
```

## Next Steps

1. **Run `xcodebuild` again** - The package should now resolve correctly
2. **Fix any type mismatches** - Once CashuSwift is downloaded, there may be API differences
3. **Update Package.resolved** - Xcode will update this automatically

## Alternative Solutions

If using the main branch is not desired, you could:
1. Use a specific commit hash:
   ```
   requirement = {
       revision = "abc123...";
       kind = revision;
   };
   ```
2. Ask the CashuSwift maintainer to tag a release
3. Fork CashuSwift and tag your own version

## Verification

After this fix, run:
```bash
xcodebuild -resolvePackageDependencies
```

This should successfully download CashuSwift from the main branch.