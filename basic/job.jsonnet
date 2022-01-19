local images = import '../images.jsonnet';
[{
  apiVersion: 'batch/v1',
  kind: 'Job',
  metadata: {
    name: 'sample',
  },
  spec: {
    template: {
      spec: {
        containers: [{
          name: 'sample',
          image: images.alpine,
          command: ['echo', 'hello'],
        }],
        restartPolicy: 'OnFailure',
      },
    },
  },
}]
