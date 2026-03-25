# Tutoriel utilisateur Visufoncier

## Étape 1 : Accéder à l'outil
Cliquez sur ce lien pour accéder à l'outil Visufoncier : [Visufoncier](https://geobretagne.fr/app/visufoncier)

<p align="center">
  <img src="https://raw.githubusercontent.com/geobretagne/visufoncier/main/documentation/images/page_accueil.png" alt="Capture d'écran de la page d'accueil" width="600"/>
</p>
<p align="center"><em>Voici la capture d'écran de la page d'accueil de l'outil Visufoncier.</em></p>

---

## Étape 2 : Choisir la période d'analyse du MOS

Le tableau de bord permet d'analyser l'évolution du Mode d'Occupation du Sol (MOS) sur **trois périodes** :

| Période | Description |
|---|---|
| **2011 – 2021** | Analyse sur la période historique de référence |
| **2021 – 2024** | Analyse sur la période récente |
| **2011 – 2024** | Analyse sur l'ensemble de la période disponible |

Sélectionnez la période souhaitée depuis le filtre temporel situé en haut du tableau de bord, puis cliquez sur **Apply Filter**. Tous les graphiques et indicateurs se mettent à jour en fonction de la période sélectionnée.

<p align="center">
  <img src="https://raw.githubusercontent.com/geobretagne/visufoncier/main/documentation/images/tempo.png" alt="Filtre temporel" width="200"/>
</p>
<p align="center"><em>Sélection de la période d'analyse du MOS.</em></p>

---

## Étape 3 : Choisir l'échelle d'analyse
Sélectionnez le niveau d'analyse souhaité :
- Régional
- Départemental
- SCOT (Schéma de Cohérence Territoriale)
- EPCI (Établissement Public de Coopération Intercommunale)
- Communal

<p align="center">
  <img src="https://raw.githubusercontent.com/geobretagne/visufoncier/main/documentation/images/niveau_territorial.png" alt="Niveau territorial" width="200"/>
</p>
<p align="center"><em>Exemple de sélection de niveau territorial.</em></p>

---

## Étape 4 : Sélectionner votre territoire

<div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 20px;">
  <p style="flex: 1;">Choisissez votre territoire (département, région, commune, EPCI ou SCOT). Vous pouvez sélectionner plusieurs territoires à la fois.
  <strong>Remarque :</strong> Les données disponibles se limitent à la région Bretagne.
  <ul>
    <li>Pour l'OCS GE NG, l'accès aux données du Morbihan n'est pas disponible pour le moment.</li>
    <li>Pour le SCOT du Pays de Redon, les données du 44 ne sont pas accessibles.</li>
  </ul>
  </p>
  <p align="center">
    <img src="https://raw.githubusercontent.com/geobretagne/visufoncier/main/documentation/images/territoire.png" alt="Sélection de territoire" width="200" />
  </p>
  <p align="center"><em>Exemple de sélection de territoire.</em></p>
</div>

---

## Étape 5 : Appliquer les filtres géographiques

Cliquez sur le bouton **Apply Filter** pour appliquer vos sélections géographiques.

---

## Étape 6 : Explorer les données

### Cross-filtres : filtrer dynamiquement depuis les graphiques

En plus des filtres géographiques et temporels, il est possible de **filtrer les graphiques directement en cliquant sur un élément d'un graphique**. C'est ce qu'on appelle le cross-filtre.

**Exemple :** Dans un graphique de répartition des flux de consommation par type d'usage, cliquer sur la catégorie *Habitat* mettra automatiquement à jour tous les autres graphiques de l'onglet pour n'afficher que les flux liés à l'habitat.

Cette fonctionnalité est disponible dans **tous les onglets** du tableau de bord.

> ⚠️ **Attention :** Les cross-filtres agissent uniquement sur les graphiques et tableaux. Ils **ne modifient pas** le territoire affiché en haut du tableau de bord, ni les cartographies. Pour filtrer sur un territoire précis ou changer de commune, utilisez les filtres géographiques en haut de page (voir étape 5).


---

### Téléchargement des données

Tous les tableaux de données sont téléchargeables en **CSV**, **Excel** ou **Image** en cliquant sur les **« ... »** situés à droite de chaque tableau, puis en sélectionnant **Download**.

> ⚠️ **Attention :** Si une seule commune est filtrée, une seule commune apparaîtra dans les tableaux de données par commune.

---

### Graphiques et tableaux
Parcourez les onglets pour découvrir les chiffres du MOS et de l'OCS GE NG. Vous aurez également accès aux flux de consommation provenant des fichiers fonciers du CEREMA, ainsi qu'aux données de l'INSEE telles que la population, l'emploi, les ménages et la densité. De plus, vous pourrez consulter les documents d'urbanisme tels que les PLU, cartes communales et zones de prescription.

#### Description des onglets :

- **Synthèse**
  - Consommation : Flux de consommation global et hors PENE, PER, INFRA ; cartographie des flux de consommation en hectares par commune
  - Artificialisation : Flux d'artificialisation brut et net, flux de désartificialisation

- **Consommation**
  - Analyse en flux du MOS : Nature et répartition des flux, pourcentage d'évolution, renaturation d'espaces en hectares, analyse sur le nombre et la densité de logements issus des fichiers fonciers et les données consommées en habitat du MOS
  - Analyse en stock du MOS : Stock en hectares, possibilité de densification (chiffres et cartographie), nature des surfaces restantes non consommées

- **Artificialisation**
  - Analyse en flux de l'OCS GE : Nature et répartition des flux de couverture et d'usage
  - Analyse en stock de l'OCS GE : Stock en hectares, stock par catégories pour la couverture et l'usage, surfaces restantes non artificialisées

- **Croisement avec le GPU**
  - PLU x MOS :
    - Cartographie du croisement MOS et PLU/PLUi sur **4 analyses** : 2024 globale, 2024 ajustée, 2021 globale, 2021 ajustée
    - Surfaces en hectares des zones ENAF mobilisables sur les zones PLU/PLUi et cartes communales, par type de zone (U, AUc, AUs), disponibles en version **brute** et **ajustée** pour les millésimes **2021** et **2024**
  - PLU x OCS GE : En cours de développement

- **Indicateurs** : Population municipale, nombre d'emplois au lieu de travail, pourcentage de densité humaine, nombre de ménages, nombre et densité de logements

- **Nomenclatures** :
  - MOS : Table des codes et leurs correspondances
  - OCS GE : Table des codes de la couverture et usage du sol. Matrice de passage

- **Cartes** :
  - MOS : Données du MOS par catégories détaillées, simplifiées ou ENAF vs CONSO ; type de consommation (déjà consommé en 2011, consommation 2011-2021, consommation 2021-2024, INFRA, PENE, PER)

<p align="center">
  <img src="https://raw.githubusercontent.com/geobretagne/visufoncier/main/documentation/images/explore_data.png" alt="Explorer les données" width="600"/>
</p>
<p align="center"><em>Exemple d'analyses disponibles sur le MOS et l'OCS GE NG.</em></p>

---

### Cartographies et visualisations
Parcourez les cartographies dans différents onglets :
- **Synthèse** : Flux de consommation par commune
- **Consommation / Analyse en stock du MOS** : Possibilité de densification
- **Croisement avec le GPU / PLU x MOS** : Analyse croisant les ENAF au MOS avec les PLU/PLUi/CC (déduction des zones de prescription) en zones U, AUc, AUs — disponible pour 2021 et 2024, en version brute et ajustée
- **Cartes** : Données du MOS par catégories, type de consommation par période (2011-2021, 2021-2024)

Les cartographies concernant les données de l'OCS GE NG sont en développement.

<p align="center">
  <img src="https://raw.githubusercontent.com/geobretagne/visufoncier/main/documentation/images/map_2.png" alt="Explorer les données carto" width="600"/>
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/geobretagne/visufoncier/main/documentation/images/map_3.png" alt="Explorer les données carto" width="600"/>
</p>
<p align="center"><em>Cartographies dans l'onglet "Cartes".</em></p>


