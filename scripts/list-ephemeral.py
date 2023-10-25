from dataclasses import dataclass
import json
import math
import subprocess


def human_file_size(size):
    i = math.floor(math.log(size) / math.log(1024)) if size != 0 else 0
    return f"{size / math.pow(1024, i):8.2f} {['B', 'kB', 'MB', 'GB', 'TB'][i]}"


@dataclass
class Pod:
    name: str
    namespace: str
    ephemeral_storage: int

    def __repr__(self):
        return f"{human_file_size(self.ephemeral_storage)}  {self.namespace}/{self.name}"

    @classmethod
    def from_summary(cls, summary):
        return cls(
            name = summary["podRef"]["name"],
            namespace = summary["podRef"]["namespace"],
            ephemeral_storage = summary["ephemeral-storage"]["usedBytes"]
        )


pods = []

for node in (x.removeprefix("node/") for x in subprocess.check_output(["kubectl", "get", "nodes", "-oname"]).decode('ascii').splitlines()):
    data = json.loads(subprocess.check_output(["kubectl", "get", "--raw", f"/api/v1/nodes/{node}/proxy/stats/summary"]))
    pods.extend(map(Pod.from_summary, data["pods"]))

pods.sort(key=lambda x: x.ephemeral_storage, reverse=True)
print('\n'.join(map(str, pods)))
