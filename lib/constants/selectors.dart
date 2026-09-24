/// Quotes per page on the Today feed.
///
/// Shared with the interests picker's prefetch: that warms
/// fetchAllQuotesProvider with this exact page size, and the provider is keyed
/// by its arguments, so a mismatch here would silently warm a different
/// instance and Today would refetch from scratch.
const int kHomeQuotePageSize = 10;
