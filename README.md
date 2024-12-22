# Kubernetes and application observability demo with Cribl

## [Prerequisites](./PREREQUISITES.md)
* `kubectl`
* `kind`
* `helm`
* Sign up for ngrok free tier: https://dashboard.ngrok.com/login

## Setup
* [Deploy Cribl Stream components](./cribl/stream/STREAM_SETUP.md)
* [Deploy Cribl Edge components](./cribl/edge/EDGE_SETUP.md)
* [Deploy the Elastic stack](./elastic/ELASTIC_SETUP.md)
* [Deploy the `otel-demo` app](./otel-demo/APP_SETUP.md)
* [To support Search replay, deploy the `ngrok` reverse tunnel](./ngrok/NGROK_SETUP.md)

## Demo material
* [Presentation](https://docs.google.com/presentation/d/1YpUe1XLNAUBW9JwJXoqTwcCjkkNiwUHTxUXfimFOnck/edit#slide=id.g2e67515ea38_0_847)
* [Recording](https://cribl.zoom.us/rec/share/kUJe_50eWgm4dk1RA48DpbCmC4gv9oxfLui6ZyqD-3PLgppc3flHzOYoOdyXdqkh.ZRROFJhnwAhwUccZ) Password: $hQM2F#w

## Diagram
![diagram](images/k8s-o11y-demo.png)