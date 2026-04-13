{ lib, ... }:

{
  options.cytopia.programs.browsers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { config, ... }:
        let
          cfg = config.features.hardware.machineLearning;
        in
        {
          ###
          ### 1. FEATURE OPTIONS
          ###
          options.features.hardware.machineLearning = {

            enableWebNn = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Enables the Web Neural Network API for GPU-accelerated Machine Learning.
                This is required to hardware-accelerate local computer vision tasks like
                Google Meet's background blur and face tracking.
              '';
            };
          };

          ###
          ### 2. CONFIGURATION
          ###
          config = {

            internal.enableFeatures = lib.mkMerge [
              (lib.optionals cfg.enableWebNn [
                "WebMachineLearningNeuralNetwork"
              ])
            ];

            internal.disableFeatures = lib.mkMerge [
              (lib.optionals (!cfg.enableWebNn) [
                "WebMachineLearningNeuralNetwork"
              ])
            ];
          };
        }
      )
    );
  };
}
