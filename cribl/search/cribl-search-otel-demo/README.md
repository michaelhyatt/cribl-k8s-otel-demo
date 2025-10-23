# Collection of dashboards to use with OTel k8s demo
----

This is a demo pack for Cribl Search around demoing Otel and k8s


##  SETUP

Before you begin, ensure that you have met the following requirements:

* setup the otel demo with k8s, edge, stream, ngrok...[per the doc](https://github.com/michaelhyatt/cribl-k8s-otel-demo/tree/main)
* Change the macros *replayURL* within this pack : replace with your own ngrok URL, with double quotes : it should look like : "https://xxx.ngrok-free.dev"
* Make sure the dataset used are otel_logs, otel_metrics [per the doc](https://github.com/michaelhyatt/cribl-k8s-otel-demo/tree/main)
* For k8s logs : assign the datatype *oteldemo_K8s_logs* to the k8s dataset (should be k8s_logs and k8s_metrics)

## Todo list

add Otel DA : dashboard and macro for DA dataset
add K8s dashboard and datatype





## Release Notes

### Version 0.0.2 
Simon Duchene : adding auto tail based sampling to automatically send baseline and abnormal traces


### Version 0.0.1 
Michael Hyatt initial version


## Contributing to the Pack
To contribute to the Pack, please do the following:



## Contact
To contact us please email <your-email@example.com>.


## License
This Pack uses the following license: [`<license_name>`](https://link-to-license-example.com).
