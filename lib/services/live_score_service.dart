/// Live score requests must go through your own secure backend.
/// Never place a paid football API key directly inside the Android app.
class LiveScoreService {
  final String backendBaseUrl;

  LiveScoreService({required this.backendBaseUrl});

  // Next step: implement calls to your backend endpoints:
  // GET /fixtures/live
  // GET /fixtures?date=YYYY-MM-DD
  // GET /fixtures/{id}
  // GET /leagues/{id}/standings
  // GET /fixtures/results?from=...&to=...
}
