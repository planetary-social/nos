/// Kind of counter (used when displaying a Note)
enum RepliesDisplayType {
    /// Don't show anything
    case displayNothing

    /// Just show "in discussion" or "Join the discussion"
    case discussion

    /// Show the number of replies
    case count
}
