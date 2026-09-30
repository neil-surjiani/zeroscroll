/// Allowed visual browsing modes inside the guarded container.
enum WebviewMode {
  /// Inbox and active conversation threads.
  directMessages,

  /// Account activity and notification lists.
  notifications,

  /// Single post or reel sent within a direct message thread (strict isolated view).
  singleMediaViewer,
}
