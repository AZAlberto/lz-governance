# Azure sin caos: Landing Zones con Terraform

> *Una aproximación práctica para desplegar, gestionar y gobernar entornos empresariales en Azure usando Terraform.*

---

## Índice
- [🚨 El problema](#-el-problema)
- [🧠 La solución](#-la-soluci%C3%B3n)
- [🏗️ Arquitectura](#-arquitectura)
- [Requisitos](#requisitos)
- [🚀 Cómo desplegar](#-c%C3%B3mo-desplegar)
- [🔥 Demo](#-demo)
- [💡 Lecciones aprendidas](#-lecciones-aprendidas)
- [Estructura del repositorio](#estructura-del-repositorio)

---

## 🚨 El problema

Azure no falla de golpe.
Se degrada poco a poco...

El caos y la deuda técnica no aparecen de un día para otro en la nube. Empiezan con pequeñas decisiones tácticas que, acumuladas en el tiempo, provocan:
- **Subscripciones sin control**: Creación de recursos sin una convención de nombres o etiquetado corporativo.
- **Permisos inconsistentes**: Usuarios con rol de `Owner` o `Contributor` a nivel de suscripción, violando el principio de mínimo privilegio.
- **Falta de gobierno**: Redes virtuales aisladas, grupos de seguridad de red (NSG) abiertos (`0.0.0.0/0`) y recursos huérfanos generando costes mes a mes.

## 🧠 La solución

Una **Landing Zone** bien diseñada desde el inicio, aplicando principios de arquitectura para la nube:

- **Jerarquía clara**: Alineación de *Management Groups* y suscripciones basándose en el ciclo de vida de las cargas de trabajo (Platform vs. Landing Zones).
- **Gobierno como código**: Uso de Azure Policies asignadas vía Terraform para forzar y auditar reglas de negocio (ej. tags obligatorias, restricciones de regiones).
- **Seguridad por defecto**: Bloqueos de borrado (*Resource Locks*), segmentación de red con topología *Hub & Spoke* y centralización de logs.

## 🏗️ Arquitectura

La infraestructura implementada sigue el modelo base Enterprise-Scale:

```ascii
                                 ┌─────────────────────────────┐
                                 │      [lz-root] (Root MG)    │
                                 └───────┬────────┬────────────┘
                                         │        │
                   ┌─────────────────────┘        └──────────────────────┐
                   ▼                                                     ▼
        ┌──────────────────┐                                   ┌───────────────────┐
        │  [lz-platform]   │                                   │ [lz-landingzones] │
        │ (Platform MG)    │                                   │ (Workloads MG)    │
        └────────┬─────────┘                                   └──────────┬────────┘
                 │                                                        │
        ┌────────▼─────────┐                                   ┌──────────▼────────┐
        │ Subscription     │◀─ VNet Peering (Hub & Spoke) ────▶│ Subscription      │
        │ - Hub VNet       │                                   │ - Spoke VNet      │
        │ - Log Analytics  │                                   │ - App Workload    │
        │ - Firewall       │                                   │ - Required Tags   │
        └──────────────────┘                                   └───────────────────┘
```

## Requisitos

- **Terraform ≥ 1.5.0**: Para el aprovisionamiento de infraestructura.
- **Azure CLI (`az`)**: Para autenticarse en el tenant de Azure.
- Permisos elevados en el Tenant de Entra ID (`Global Administrator` / `User Access Administrator` en el Root Management Group) para desplegar jerarquías completas.

> **Tip:** Puedes usar un *Service Principal* para automatizar esto desde pipelines (GitHub Actions, Azure DevOps).

---

## 🚀 Cómo desplegar

El despliegue está dividido en capas lógicas para minimizar el Radio de Explosión (*Blast Radius*) y separar responsabilidades.

### 1. Bootstrap
Aprovisiona las bases fundacionales de la Landing Zone.
- Crea la jerarquía de **Management Groups**.
- Crea el `Storage Account` para almacenar de forma segura el estado de Terraform (`tfstate`).

```bash
cd src/1-bootstrap
terraform init
terraform plan -out=tfplan
terraform apply "tfplan"
```

### 2. Platform
Construye la conectividad y observabilidad central.
- Despliega el **Hub VNet** con subredes preparadas para Azure Firewall y Bastion.
- Configura el **Log Analytics Workspace** centralizado para recolectar diagnóstico y métricas.

```bash
cd ../2-platform
terraform init && terraform apply -auto-approve
```

### 3. Landing Zone
Levanta un entorno final para aplicaciones.
- Crea un *Spoke VNet* (simulando una red para un backend/frontend).
- (De manera ilustrativa) Asigna **Azure Policies** para forzar normativas corporativas, requiriendo una etiqueta de ambiente en el Resource Group.

```bash
cd ../3-landing-zone
terraform init && terraform apply -auto-approve
```

---

## 🔥 Demo

Aprender viendo los errores es la mejor manera de entender la importancia del gobierno. Dentro del directorio `demos/`, encontrarás dos escenarios:

### `demos/broken` → Caos
Simula un equipo desplegando sin normativas:
- Creación de recursos **sin etiquetas**.
- Un **Network Security Group (NSG)** exponiendo puertos críticos (como el 22) directamente a Internet (`0.0.0.0/0`).
- Máquinas virtuales conectadas directamente con **IP pública**.
👉 *Resultado: Entorno vulnerable y sin trazabilidad.*

### `demos/fixed` → Solución
Demuestra cómo aplicar políticas correctivas en la Landing Zone:
- **Etiquetado** estandarizado en todos los recursos creados.
- Reglas de NSG estrictas aplicando *Zero Trust*, limitando acceso de administración únicamente a IPs corporativas predefinidas.
- **Resource Locks** aplicados a nivel de Resource Group para evitar el borrado accidental por error humano.
- Arquitectura sin IPs públicas directas, conectándose de forma privada.

---

## 💡 Lecciones aprendidas

1. **El caos empieza antes de lo que crees**: Saltarse el uso de `tfstate` remoto o hacer un "clic rápido en el portal para probar", son las primeras grietas del desastre.
2. **Governance no es opcional**: Implementar políticas no ralentiza el desarrollo si se automatiza desde el inicio. Es mejor que el código falle rápidamente (*Shift Left*) a auditar semanas después.
3. **Terraform sin diseño = desastre automatizado**: Escribir `main.tf` gigantescos no te hace "Cloud Native". Separar en módulos (Bootstrap -> Platform -> Workloads) facilita la colaboración y previene destrucción masiva.

---

## Estructura del repositorio

```text
lz-governance/
├── README.md               # Esta documentación
├── src/                    # Código estructurado de la Landing Zone
│   ├── 1-bootstrap/        # MGs y almacenamiento de tfstate
│   ├── 2-platform/         # Hub de VNet y logs centralizados
│   └── 3-landing-zone/     # Entornos segmentados y políticas
└── demos/                  
    ├── broken/             # Entorno mal configurado (Ejemplo de caos)
    └── fixed/              # Entorno protegido (Aplicando mejores prácticas)
```

---

> *Inspirado por Microsoft Cloud Adoption Framework y las experiencias en el campo.*
