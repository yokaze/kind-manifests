local images = import '../images.jsonnet';
[
  {
    apiVersion: 'v1',
    kind: 'Namespace',
    metadata: {
      name: 'spire-sample',
    },
  },
  {
    apiVersion: 'v1',
    kind: 'ServiceAccount',
    metadata: {
      namespace: 'spire-sample',
      name: 'gallery',
    },
  },
  {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: {
      namespace: 'spire-sample',
      name: 'sample',
    },
    data: {
      'spiffe-helper.conf': |||
        agent_address = "/spiffe-workload-api/spire-agent.sock"
        cert_dir = "/certs"
        svid_file_name = "tls.crt"
        svid_key_file_name = "tls.key"
        svid_bundle_file_name = "ca.pem"
      |||,
    },
  },
  {
    apiVersion: 'v1',
    kind: 'Pod',
    metadata: {
      namespace: 'spire-sample',
      name: 'sample',
    },
    spec: {
      serviceAccountName: 'gallery',
      containers: [{
        name: 'alpine',
        image: images.alpine,
        command: [
          'sleep',
          'inf',
        ],
        volumeMounts: [{
          mountPath: '/spiffe-workload-api',
          name: 'spiffe-workload-api',
          readOnly: true,
        }, {
          name: 'certdir',
          mountPath: '/certs',
        }],
      }, {
        name: 'spiffe-helper',
        image: 'ghcr.io/spiffe/spiffe-helper:0.8.0',
        args: [
          '-config',
          '/etc/spiffe-helper.conf',
        ],
        volumeMounts: [{
          mountPath: '/spiffe-workload-api',
          name: 'spiffe-workload-api',
          readOnly: true,
        }, {
          name: 'config',
          mountPath: '/etc/spiffe-helper.conf',
          subPath: 'spiffe-helper.conf',
          readOnly: true,
        }, {
          name: 'certdir',
          mountPath: '/certs',
        }],
      }],
      volumes: [{
        name: 'spiffe-workload-api',
        csi: {
          driver: 'csi.spiffe.io',
          readOnly: true,
        },
      }, {
        name: 'config',
        configMap: {
          name: 'sample',
        },
      }, {
        name: 'certdir',
        emptyDir: {},
      }],
    },
  },
]
