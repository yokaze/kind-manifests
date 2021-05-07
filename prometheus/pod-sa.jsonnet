std.mergePatch(import 'pod.jsonnet', {
  spec: {
    serviceAccountName: 'prometheus',
  },
})
