# Common-Scenario-Schema

The scenario-based approach is used for generation of safety-critical scenarios. It is applied for various applications ranging from development of perception and decision algorithms to the corresponding test and validation.

## Table of Contents

- [Docs](#docs)
- [Installation](#installation)
- [Usage](#usage)

## Installation

Installing Packages

```plaintext
pip install -r requirements.txt
```

`protoc` must be in your path with `protobufc` installed.

Call `set-target` with the platform you are targetting. Today only `linux` and `esp32s3` are supported.
* `idf.py set-target esp32s3`

Configure device specific settings. None needed at this time
* `idf.py menuconfig`

Set your Wifi SSID + Password as env variables
* `export WIFI_SSID=foo`
* `export WIFI_PASSWORD=bar`
* `export OPENAI_API_KEY=bing`

Build
* `idf.py build`

If you built for `esp32s3` run the following to flash to the device
* `sudo -E idf.py flash`

If you built for `linux` you can run the binary directly
* `./build/src.elf`

See [build.yaml](.github/workflows/build.yaml) for a Docker command to do this all in one step.

## Usage
