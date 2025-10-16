class: inverse, center, middle

# Kubernetes

---

# Kubernetes

- Container orchestration (bármilyen CRI implementáció, Docker, vagy akár containerd)
- Több fizikai számítógép (resource management)
- Konténerek szétosztása, életciklus (scheduling, affinity, anti-affinity)
- Deklaratív megközelítés
- Újraindítás alkalmazás/konténer hiba esetén (service management)
- Google -> CNCF
- (Google) Go-ban implementált
- [CNCF Cloud Native Interactive Landscape](https://landscape.cncf.io/?view-mode=grid&group=certified-partners-and-providers)
- Különböző disztribúciók
  - On-premises és cloud megoldások is
  - Különböző gyártók
  - Különböző igények (pl. tesztelés, limitált erőforrások)

# Részei

- Master node (Control plane)
  - API server (REST, authentication, állapotmentes)
  - etcd (key-value adatbázis, konfiguráció és aktuális állapot)
  - Scheduler (dönt, hogy mely konténer hol indítható)
  - Controller manager (elvárt állapot fenntartásért felelős, monitoring loopok, update-eli az etcd-ben az állapotot)
  - Cloud controller manager (opcionális, a cloud szolgáltatóval tartja a kapcsolatot)
- Worker node
  - kubelet (konténerek vezérlése)
  - kube-proxy (hálózat)

# Hálózat

- Cluster DNS (based on CoreDNS)

# Magas rendelkezésreállás

- Legalább három master node (elég csak az etcd-ből)
- Legalább három worker node

# Windowson

- Docker Desktop
- Single node cluster (vanilla Kubernetes, fejlesztési célra)

# Adminisztráció

- `kubectl` parancs
  - https://kubernetes.io/docs/reference/kubectl/cheatsheet/
  - Sokszor manifest fájlokat használ, melyek yaml fájlok
- GUI
  - [Lens](https://k8slens.dev/), regisztráció szükséges
  - IntelliJ IDEA
    - Plugin
    - Services
  - Visual Studio Code
    - [Visual Studio Code Kubernetes Tools](https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools)
- REST API, különböző programozási nyelven megírt kliensek

# Nodes

```
kubectl config get-contexts
kubectl config view
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
kubectl get all -A
kubectl api-resources
```

- `kubectl config view`, mögötte egy konfig fájl, hova csatlakozik a kliens, és milyen felhasználóval (ezt a parancssorban nem lehet látni csak a fájlban)
  - `%HOME%\.kube`
- namespace való pl. különböző környezetek (pl. ugyanazon a Kubernetes clusteren) megkülönböztetésére, pl. teszt, uat., stb.
- `-A` azaz `--all-namespaces`, pl. `kube-system` namespace a rendszerkomponenseknek
- resources: milyen erőforrásokat lehet kezelni, létrehozni, stb. API-n keresztül, pl. `kubectl`-lel

# Objects

- Pod
  - Bálnaraj
  - Tipikusan egy konténer
  - 0-n ún. sidecar konténer
  - Konténerek egy ip-t kapnak (vigyázni a portütközéssel), kommunikálhatnak egymással localhoston vagy socketen
  - Ideiglenes ip, hiszen bármikor történhet újraindítás
  - Halandóak, ha leáll, hibára fut, Kubernetes törli és újat indít
  - Atomic unit
- Deployment
  - Inkább ezeket használjuk, bár podot is lehet
  - Deployment része a pod definíció
  - Skálázható

# Deployment létrehozása

```
docker build -t training360/time-service:0.0.1-SNAPSHOT .
kubectl create deployment time-service --image=training360/time-service:0.0.1-SNAPSHOT --dry-run=client -o=yaml > deployment.yaml
```

Mik szerepelhetnek a yaml fájlon belül?

```shell
kubectl explain deployment
```

# Deployment strategy

- Rolling update - Párhuzamosan, a leállási idő csökkentése miatt
- Recreate - először podok törlése, majd létrehozása
