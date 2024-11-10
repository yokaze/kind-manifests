local images = import '../images.jsonnet';
local pod_base = import 'pod.jsonnet';
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
      name: 'sample',
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
        jwt_svids = [{jwt_audience="https://my-hydra/oauth2/token", jwt_svid_file_name="jwt_svid.token"}]
      |||,
    },
  },
  pod_base[0] + {
    metadata+: {
      namespace: 'spire-sample',
      name: 'sample',
    },
    spec+: {
      containers: [
        pod_base[0].spec.containers[0] + {
          volumeMounts+: [{
            name: 'certs',
            mountPath: '/certs',
          }],
        },
        {
          name: 'spiffe-helper',
          image: images.spiffe_helper,
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
            name: 'certs',
            mountPath: '/certs',
          }],
        },
      ],
      serviceAccountName: 'sample',
      volumes+: [{
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
        name: 'certs',
        emptyDir: {},
      }],
    },
  },
]
