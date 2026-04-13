{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.security.engineIsolation;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.security.engineIsolation = {

            strictProcessIsolation = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Enforces strict site-per-process isolation and cross-origin checks.
                Prevents compromised iframes or cross-site scripting from leaking memory.
                Forces the browser to spin up completely separate OS-level processes
                for every domain (even iframes). This is your primary defense against
                Spectre/Meltdown style attacks leaking data between tabs.
                Note: This imposes a 10% to 20% RAM tax and CPU/IPC overhead.
                Also strictly keys OS process memory to the specific origin.
              '';
            };

            sandboxSystemServices = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Forces the browser's internal Audio processing engine and Network
                service stack into dedicated, strict OS-level sandboxes. Prevents media
                or network parser exploits from escaping to the underlying system.
              '';
            };

            disableJit = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                DANGEROUS/EXTREME: Disables the V8 JavaScript JIT (Just-In-Time) compiler.
                This eliminates an entire class of zero-day exploits and WASM attacks,
                but heavily impacts the performance of complex web apps.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.flags = lib.mkMerge [
              (lib.optionals cfg.strictProcessIsolation [
                # Forces Chromium to allocate dedicated OS-level processes for each site.
                "--site-per-process"
              ])
              (lib.optionals cfg.disableJit [
                # Instructs the V8 JavaScript engine to run purely in interpreter mode.
                "--js-flags=--jitless"
              ])
            ];

            internal.enableFeatures = lib.mkMerge [
              (lib.optionals cfg.strictProcessIsolation [
                # Hardens the Origin API to strictly separate origins on the backend.
                # This is the nuclear version. It also separates subdomains.
                "StrictOriginIsolation"
              ])

              (lib.optionals cfg.sandboxSystemServices [
                # Runs the internal browser network service in a heavily restricted OS sandbox.
                "NetworkServiceSandbox"
              ])
            ];

            internal.policies = lib.mkMerge [
              (lib.mkIf cfg.disableJit {
                # A value of 2 strictly blocks all Just-In-Time Javascript compilation.
                "DefaultJavaScriptJitSetting" = 2;
              })

              (lib.mkIf cfg.strictProcessIsolation {
                # This policy alone enforces the --site-per-process behavior globally.
                "SitePerProcess" = true;
                # Enhances SitePerProcess by strongly keying the process memory to the specific origin.
                "OriginKeyedProcessesEnabled" = true;
              })

              (lib.mkIf cfg.sandboxSystemServices {
                "AudioSandboxEnabled" = true;
                "NetworkServiceSandboxEnabled" = true;
              })
            ];
          };
        }
      )
    );
  };
}
