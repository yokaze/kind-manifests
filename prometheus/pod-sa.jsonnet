std.mergePatch(import 'pod.json', {
  spec: {
    serviceAccountName: 'prometheus',
  },
})
