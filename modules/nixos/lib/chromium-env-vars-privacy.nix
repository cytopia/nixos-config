let
  default = {

    # Timezone Spoofing: Forces Chrome's JS engine to report UTC instead of your real local timezone.
    # Blends your browser fingerprint into the largest generic pool of users, masking your physical location.
    # Disabled: This can show a difference to the Javascript fetched timezone
    #"TZ" = "UTC";

    # Locale/Language Spoofing: Normalizes date, time, number, and currency formatting.
    # Hides your specific regional OS settings, making your fingerprint generic (US English).
    "LC_ALL" = "en_US.UTF-8";

    # TLS Key Leak Prevention: Explicitly routes the TLS pre-master secret log to /dev/null.
    # Ensures that rogue Wayland processes or accidental exports cannot dump and decrypt your secure HTTPS web traffic.
    "SSLKEYLOGFILE" = "/dev/null";

    # Hard-Block Google API Services: Injects invalid API keys into the environment.
    # Acts as a kill-switch. Even if telemetry policies fail, Chrome's requests to Google's backend
    # (Translate, Geolocation, SafeBrowsing) will be rejected with an authentication error.
    "GOOGLE_API_KEY" = "no";
    "GOOGLE_DEFAULT_CLIENT_ID" = "no";
    "GOOGLE_DEFAULT_CLIENT_SECRET" = "no";
  };
in
{
  # Exposed library properties completely free of conjunctions
  default = default;
}
