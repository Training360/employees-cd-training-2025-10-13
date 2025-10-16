## Bevezetés a GitHub Actions használatába

- Munkafolyamatok automatizálására, de ebből csak egy a CI/CD

Képességei:

- VM (hosted v. self-hosted), containers
- Matrix build, különböző operációs rendszereken, interpreter verziókon, stb.
- Integráció a GitHub repository-kkal, és GitHub Packages-zel, Package Registry-vel

Szóhasználat:

- Workflow: yaml formátumú leíró fájl
- Run: workflow egy futtatása
- Runner: gép, melyen a run fut

További szóhasználat:

- Event: ennek hatására indul egy a workflow, azaz egy run
  - Creates a PR
  - Contributor joined
  - Opens an issue
  - Pushes a commit to a repository
  - PR merged
  - Kapcsolt eszközök is tudnak eventet küldeni
- Job
  - Alapvető futtatási egység
  - Step-ekből áll
  - Egy jobot ugyanaz a runner futtatja, azaz a benne lévő steppeket is
  - Jobok alapból párhuzamosan futnak
  - Lehet közöttük függőséget definiálni, akkor szekvenciálisan
  - Külön jobok külön runneren futnak, nem osztozhatnak a fájlokon
  - Jobok között fájlátvitel: cache, artifact
- Step
  - Job legkisebb végrehajtási egysége
  - Típusai
    - Parancsot hajt végre (`run`)
    - Actiont használ (`uses`)
  - Egy jobhoz tartozó step-ek ugyanazon runneren futnak
  - Jobon belül sorrendben futnak
- Action
  - Újrafelhasználható végrehajtási egység
  - [GitHub Marketplace](https://github.com/marketplace)
  - Típusai:
    - Official
    - Community
    - Custom

## Protected branch

Ha egy branch protected, akkor bizonyos műveletek tiltva vannak közvetlenül rajta, például:

- nem lehet közvetlenül pusholni (git push) rá,
- nem lehet force pusholni (git push --force),
- nem lehet kitörölni az ágat.

Ehelyett a módosításokat pull requesten (PR) keresztül kell bevinni, ami review-n és automatikus ellenőrzéseken megy át.

- Csak ha a CI/CD build sikeres
- Jóváhagyták

## Hello World GitHub Actions workflow

```yaml
name: Build

on:
  push:
    branches:
      - master
  workflow_dispatch:

jobs:
  say-hello:
    runs-on: ubuntu-latest
    steps:
      - name: Say Hello
        run: echo "Hello, World from GitHub Actions!"
```

- Javasolt eszköz: webes felület

- Javasolt eszköz: GitHub CLI

```shell
gh workflow
gh workflow list
gh workflow run Build
gh workflow view Build
gh run
gh run view [id]
gh run watch [id]
```

- Javasolt eszköz: GitHub Actions Visual Studio Code extension

## Build

[setup-java](https://github.com/marketplace/actions/setup-java-jdk)

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v5
      - name: Set up Java 24
        uses: actions/setup-java@v5
        with:
          distribution: "temurin"
          java-version: "24"
      - name: Build with Maven
        run: mvn -B package
```

[GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)

`mvn -B`: Batch mode, CI rendszer számára

Commit mellé is odaírja a build eredményét

IDEA-ban a Git Log ablakban is megjelenik

## Cache

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v5
      - name: Set up Java 24
        uses: actions/setup-java@v5
        with:
          distribution: "temurin"
          java-version: "24"
          cache: "maven"
      - name: Build with Maven
        run: mvn package
```

## Párhuzamos futtatás

```yaml
jobs:
  # ...

  integration-tests:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - run: echo "Integration tests go here"

  owasp-scan:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - run: echo "OWASP scan goes here"

  sonarqube-scan:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - run: echo "SonarQube scan goes here"
```

## Integrációs tesztelés

Sajnos ha a `target` könyvtárat artifact-ként emeljük át:

- A források frissebbek lesznek, mint a `target` könyvtár fájljai, ezért mindenképp
  újra fordít
- IO overhead
- Max. 2 GB méret

```yaml
jobs:
  integration-tests:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Checkout repository
        uses: actions/checkout@v5
      - name: Set up Java 24
        uses: actions/setup-java@v5
        with:
          distribution: "temurin"
          java-version: "24"
          cache: "maven"
      - name: Run integration tests with Maven
        run: mvn verify
```

Ötlet: teljes projekt becsomagolása és kicsomagolása

Sajnos a `actions/download-artifact@v4` nem képes megtartani a fájlok timestamp-jét

Megoldás lehet: manuális tömörítés és kitömörítés (`tar.gz` létrehozása)

## Integrációs tesztelés MariaDB adatbázissal

```yaml
jobs:
  integration-tests:
    runs-on: ubuntu-latest
    needs: build
    services:
      mariadb:
        image: mariadb:12
        ports:
          - 3306:3306
        env:
          MARIADB_ALLOW_EMPTY_ROOT_PASSWORD: yes
          MARIADB_USER: employees
          MARIADB_PASSWORD: employees
          MARIADB_DATABASE: employees
        options: >-
          --health-cmd="healthcheck.sh --connect --innodb_initialized"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5
    steps:
      - name: Checkout repository
        uses: actions/checkout@v5
      - name: Set up Java 24
        uses: actions/setup-java@v5
        with:
          distribution: "temurin"
          java-version: "24"
          cache: "maven"
      - name: Run integration tests with Maven
        run: mvn -Dtest.datasource.url=jdbc:mariadb://localhost/employees -Dtest.datasource.username=employees -Dtest.datasource.password=employees verify
```

## Job kikapcsolása

- `if: false`, felületen megjelenik, de szürkén, skipped állapotban
- Megjegyzésbe tenni

## Docker image és push a DockerHub-ra (Secrets)

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      packages: write
    steps:
      - name: Login to DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME  }}
          password: ${{ secrets.DOCKERHUB_TOKEN  }}
      - name: Create and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          tags: ${{ secrets.DOCKERHUB_USERNAME  }}/employees:latest
          push: true
```

- Settings → Secrets and variables → Actions → New repository secret

```
DOCKERHUB_USERNAME=
DOCKERHUB_TOKEN=
```

- Delete repository
- Delete token

## Docker image és push a GitHub Container Registry-be

```
Error: buildx failed with: ERROR: failed to build: denied: installation not allowed to Create organization package
```

- packages write permission kell

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      packages: write
    steps:
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Create and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          tags: ghcr.io/${{ github.repository }}:latest
          push: true
```

Packages-ben

## Docker image külön jobban

```yaml
jobs:
  build:
    steps:
      - name: Archive production artifacts
        uses: actions/upload-artifact@v4
        with:
          name: employees
          path: target/employees-*.jar
```

```yaml
jobs:
  create-image:
    runs-on: ubuntu-latest
    needs: build
    permissions:
      packages: write
    steps:
      - name: Checkout repository
        uses: actions/checkout@v5
      - name: Download production artifacts
        uses: actions/download-artifact@v4
        with:
          name: employees
          path: target/
      - run: ls -R
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Create Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          tags: ghcr.io/${{ github.repository }}:latest
          push: true
```

Megjelenik az Artifacts panel

## Verzió használata

- `$GITHUB_ENV` - steppek között környezeti változóhoz
- `$GITHUB_OUTPUT` - jobok között

Maven `pom.xml`

```xml
<version>${build.number}</version>

<properties>
  <build.number>unknown</build.number>
</properties>
```

```shell
mvn package -Dbuild.number=1.0.0-demo
```

Csak a verziószám kiírása:

`Dockerfile`

```Dockerfile
COPY target/employees-*.jar employees.jar
```

```yaml
jobs:
  build:
    outputs:
      version: ${{ steps.set_version.outputs.version }}
    steps:
      - name: Set version
        id: set_version
        run: |
          VERSION="1.0.0-${GITHUB_RUN_NUMBER}"
          echo "Version: $VERSION"            
          echo "VERSION=$VERSION" >> $GITHUB_ENV
          echo "version=$VERSION" >> $GITHUB_OUTPUT

  create-image:
    steps:
      - name: Read version
        run: |
          VERSION=${{ needs.build.outputs.version }}
          echo "VERSION=$VERSION" >> $GITHUB_ENV
          echo "Version from build job: $VERSION"
      - name: Create Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          tags: ghcr.io/${{ github.repository }}:latest, ghcr.io/${{ github.repository }}:${{ env.VERSION }}
          push: true
```

## Workflow letiltása

- Felületen Disable
- `if: false` az első job-hoz
- Megjegyzésbe tenni

## Konfig repo

Új repo, chart átmásolása

Access token generálása: User Settings / Developer Settings / Personal access tokens / Fine-grained tokens

Contents / Read and write

Az application repo-ba felvenni a Actions secret-ek közé: `CONFIG_REPO_GITHUB_TOKEN`

## Írás a config repo-ba

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    needs:
      - build
      - build-image
    steps:
      - run: echo "Deploy application here"
      - name: Checkout code
        uses: actions/checkout@v5
        with:
          repository: vicziani/employees-config-2025-10-08
          token: ${{ secrets.CONFIG_REPO_GITHUB_TOKEN }}
      - name: Read version from build job
        run: |
          VERSION=${{ needs.build.outputs.version }}
          echo "VERSION=$VERSION" >> $GITHUB_ENV
          echo "Version from build job: $VERSION"
      - name: Update deployment manifest
        run: |
          yq e '.image.tag = "${{ env.VERSION }}"' -i values.yaml
          cat values.yaml
      - name: Commit and push changes
        run: |
          git config user.name "github-actions"
          git config user.email "github-actions@users.noreply.github.com"
          git commit -am "chore: update image version to $VERSION"
          git push
```

## ArgoCD

App repo Package visibility: public

```shell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl exec -n argocd deploy/argocd-server -- argocd admin initial-password -n argocd
```

```shell
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

`application.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: employees
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/vicziani/employees-config-2025-10-08
    path: .
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated: {}
```

```shell
kubectl apply -f application.yaml  -n argocd
```

## Act

[Act](https://github.com/nektos/act)

```sh
gh extension install https://github.com/nektos/gh-act
```
