$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$results = Join-Path $PSScriptRoot "results"
New-Item -ItemType Directory -Force $results | Out-Null

Push-Location $root
try {
    iverilog -g2012 -o verification\results\tb_color_detector.vvp verification\tb_color_detector.v src\vision\color_detector.v src\color_detect_timer.v
    vvp verification\results\tb_color_detector.vvp | Tee-Object -FilePath verification\results\color_detector.log

    iverilog -g2012 -o verification\results\tb_shape_classifier.vvp verification\tb_shape_classifier.v src\vision\shape_classifier.v
    vvp verification\results\tb_shape_classifier.vvp | Tee-Object -FilePath verification\results\shape_classifier.log
}
finally {
    Pop-Location
}
