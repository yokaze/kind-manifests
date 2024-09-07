[
  {
    apiVersion: 'trust.cert-manager.io/v1alpha1',
    kind: 'Bundle',
    metadata: {
      name: 'cluster-ca',
    },
    spec: {
      sources: [
        {
          secret: {
            name: 'cluster-ca',
            key: 'ca.crt',
          },
        },
      ],
      target: {
        configMap: {
          key: 'ca.crt',
        },
      },
    },
  },
  {
    apiVersion: 'cert-manager.io/v1',
    kind: 'Certificate',
    metadata: {
      name: 'https-server',
    },
    spec: {
      secretName: 'https-server',
      dnsNames: [
        'https-server.default.svc',
      ],
      issuerRef: {
        name: 'cluster-ca',
        kind: 'ClusterIssuer',
        group: 'cert-manager.io',
      },
    },
  },
  {
    apiVersion: 'v1',
    kind: 'Pod',
    metadata: {
      name: 'https-server',
      labels: {
        'app.kubernetes.io/name': 'https-server',
      },
    },
    spec: {
      containers: [{
        name: 'python',
        image: 'python:latest',
        command: [
          'python3',
          '/etc/https-server-script/script.py',
        ],
        volumeMounts: [{
          name: 'https-server',
          mountPath: '/etc/https-server',
          readOnly: true,
        }, {
          name: 'https-server-script',
          mountPath: '/etc/https-server-script',
          readOnly: true,
        }],
      }],
      volumes: [{
        name: 'https-server',
        secret: {
          secretName: 'https-server',
        },
      }, {
        name: 'https-server-script',
        configMap: {
          name: 'https-server-script',
        },
      }],
    },
  },
  {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: {
      name: 'https-server-script',
    },
    data: {
      'script.py': importstr '../trust-manager-gallery/script.py',
    },
  },
  {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: 'https-server',
    },
    spec: {
      ports: [{
        name: 'http',
        port: 80,
        targetPort: 8080,
      }, {
        name: 'https',
        port: 443,
        targetPort: 8443,
      }],
      selector: {
        'app.kubernetes.io/name': 'https-server',
      },
    },
  },
  {
    apiVersion: 'v1',
    kind: 'Pod',
    metadata: {
      name: 'https-client',
    },
    spec: {
      containers: [{
        name: 'ubuntu',
        image: 'ubuntu:24.04',
        command: [
          'bash',
          '-c',
          'apt-get update && apt install -y curl && apt remove --purge -y ca-certificates && sleep inf',
        ],
        volumeMounts: [{
          name: 'cluster-ca',
          mountPath: '/etc/cluster-ca',
          readOnly: true,
        }],
      }],
      volumes: [{
        name: 'cluster-ca',
        configMap: {
          name: 'cluster-ca',
        },
      }],
    },
  },
]
