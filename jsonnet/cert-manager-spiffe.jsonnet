local images = import '../images.jsonnet';
[
  {
    apiVersion: 'v1',
    kind: 'ServiceAccount',
    metadata: {
      name: 'cert-manager-spiffe',
    },
  },
  {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'RoleBinding',
    metadata: {
      name: 'cert-manager-spiffe',
    },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: 'cert-manager-edit',
    },
    subjects: [{
      kind: 'ServiceAccount',
      namespace: 'default',
      name: 'cert-manager-spiffe',
    }],
  },
  {
    apiVersion: 'v1',
    kind: 'Pod',
    metadata: {
      name: 'cert-manager-spiffe',
    },
    spec: {
      serviceAccountName: 'cert-manager-spiffe',
      containers: [
        {
          name: 'alpine',
          image: images.alpine,
          command: [
            'sleep',
            'inf',
          ],
          resources: {
            requests: {
              cpu: '100m',
              memory: '64Mi',
            },
            limits: {
              cpu: '750m',
              memory: '192Mi',
            },
          },
          volumeMounts: [{
            name: 'spiffe',
            mountPath: '/var/run/secrets/spiffe.io',
          }],
        },
      ],
      volumes: [{
        name: 'spiffe',
        csi: {
          driver: 'spiffe.csi.cert-manager.io',
          readOnly: true,
        },
      }],
    },
  },
]
