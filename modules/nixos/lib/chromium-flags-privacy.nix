{ lib, ...}:
let

  disableCrossOriginReferrer = {
    flags = [];
    enableFeatures = [
      "NoCrossOriginReferrers"  # Block "Referer" header entirely across different domains.
      "MinimalReferrers"        # Only send domain in "Referer" if referer is set
    ];
    disableFeatures = [];
  };
  reduceSystemInfo = {
    flags = [];
    enableFeatures = [
      # Strips details from the User Agent string and Javascript API.
      # It stops websites from seeing your exact CPU model or specific Linux distro version,
      # making you look like a "Generic Linux User."
      "ReducedSystemInfo"
    ];
    disableFeatures = [];
  };
in
{
  # The New Privacy Function
  getPrivacyFlags = {
    enableDisableCrossOriginReferrer ? true,
    enableReduceSystemInfo ? false
  }:
  let
    # Empty block for falsy conditions
    empty = { flags = []; enableFeatures = []; disableFeatures = []; };

    # Map the toggles to our data blocks
    activeBlocks = [
      (if enableDisableCrossOriginReferrer then disableCrossOriginReferrer else empty)
      (if enableReduceSystemInfo then reduceSystemInfo else empty)
    ];
  in
  {
    flags = lib.concatLists (map (x: x.flags) activeBlocks);
    enableFeatures = lib.concatLists (map (x: x.enableFeatures) activeBlocks);
    disableFeatures = lib.concatLists (map (x: x.disableFeatures) activeBlocks);
  };
}
