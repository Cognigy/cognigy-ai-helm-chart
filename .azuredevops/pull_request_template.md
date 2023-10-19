# Security

Please assess your changes and describe the potential impact of your change regarding the following checklist:

- [ ] A new ingress has been added which exposes functionality to the outside world
- [ ] A new service has been added to expose functionality inside of the cluster - is the service of type NodePort?
- [ ] Annotations for services or ingress objects have been changed
- [ ] No security relevant change