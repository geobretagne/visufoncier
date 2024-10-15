# Tutoriel utilisateur Visufoncier

## Étape 1 : Accéder à l'outil
Cliquez sur ce lien pour accéder à l'outil Visufoncier : [Visufoncier](https://geobretagne.fr/app/visufoncier)

<p align="center">
  <img src="https://raw.githubusercontent.com/geobretagne/visufoncier/main/documentation/images/page_accueil.png" alt="Capture d'écran de la page d'accueil" width="600"/>
</p>
<p align="center"><em>Voici la capture d'écran de la page d'accueil de l'outil Visufoncier.</em></p>

## Étape 2 : Choisir l'échelle d'analyse
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

## Étape 3 : Sélectionner votre territoire

<div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 20px;">
  <p style="flex: 1;">Choisissez votre territoire (département, région, commune, EPCI ou SCOT). Vous pouvez sélectionner plusieurs territoires à la fois. 
  <strong>Remarque :</strong> Les données disponibles se limitent à la région Bretagne.
  <ul>
    <li>Pour l'OCS GE NG, l'accès aux données du Morbihan n'est pas disponible pour le moment.</li>
    <li>Pour le SCOT du Pays de Redon, les données du 44 ne sont pas accessibles.</li>
  </ul>
  </p>
  <p align="center">
    <img src="https://raw.githubusercontent.com/geobretagne/visufoncier/main/documentation/images/selection_territoire.png" alt="Sélection de territoire" width="200" />
  </p>
  <p align="center"><em>Exemple de sélection de territoire.</em></p>
</div>

## Étape 4 : Appliquer les filtres
Cliquez sur le bouton **Apply Filter** pour appliquer vos sélections.

<p align="center">
  <img src="https://raw.githubusercontent.com/geobretagne/visufoncier/main/documentation/images/apply_filter.png" alt="Appliquer les filtres" width="200"/>
</p>
<p align="center"><em>Exemple d'application des filtres.</em></p>

Par exemple, vous pouvez :
- Sélectionner un département, comme le Finistère.
- Revenir au niveau territorial et choisir **Commune** pour afficher uniquement les communes du Finistère dans la liste.

<p align="center">
  <img src="https://raw.githubusercontent.com/geobretagne/visufoncier/main/documentation/images/double_filtre.png" alt="Appliquer les filtres double" width="200"/>
</p>
<p align="center"><em>Application de filtres multiples.</em></p>

## Étape 5 : Explorer les données
### Graphiques et tableaux
Parcourez les onglets pour découvrir les chiffres du MOS et de l'OCS GE NG. Vous aurez également accès aux flux de consommation provenant des fichiers fonciers du CEREMA, ainsi qu'aux données de l'INSEE telles que la population, l'emploi, les ménages et la densité. De plus, vous pourrez consulter les documents d'urbanisme tels que les PLU, cartes communales et zones de prescription.
#### Description :
- Synthèse
  - Consommation : Flux de consommation brut et corrigé (infrastructures), flux de consommation selon les fichiers fonciers, cartographie des flux de consommation en hectares par commune
  - Artificialisation : Flux d'artificialisation brut et net, flux de désartificialisation
- Consommation
  - Analyse en flux du MOS : Nature et répartition des flux, pourcentage d'évolution, renaturation d'espaces en hectares, analyse sur le nombre et la densité de logements issus des fichiers fonciers et les données consommées en habitat du MOS
  - Analyse en stock du MOS : Stock en hectares, possibilité de densification (chiffres et cartographie), nature des surfaces restantes non consommées
- Artificialisation
  - Analyse en flux de l'OCS GE : Nature et répartition des flux de couverture et d'usage
  - Analyse en stock de l'OCS GE : Stock en hectares, stock par catégories pour la couverture et l'usage, surfaces restantes non artificialisées
- Croisement avec le GPU
  - PLU x MOS : Zones ENAF mobilisables sur les zones PLU/PLUi et cartes communales (deux analyses : brute et simplifiée), cartographie du croisement MOS et PLU/PLUi
  - PLU x OCS GE : En cours de développement
- Indicateurs : Population municipale, nombre d'emplois au lieu de travail, pourcentage de densité humaine, nombre de ménages, nombre et densité de logements
- Nomenclatures :
  - MOS : Table des codes et leurs correspondances
  - OCS GE : Table des codes de la couverture et usage du sol. Matrice de passage
- Cartes :
  - MOS : Espaces NAF ayant connu un flux de consommation, consommation VS ENAF, nature des surfaces en 2021

<p align="center">
  <img src="https://raw.githubusercontent.com/geobretagne/visufoncier/main/documentation/images/explore_data.png" alt="Explorer les données" width="600"/>
</p>
<p align="center"><em>Exemple d'analyses disponibles sur le MOS et l'OCS GE NG.</em></p>

### Cartographies et visualisations
Parcourez les cartographies dans différents onglets : 
- Synthèse : Flux de consommation par commune
- Consommation / Analyse en stock du MOS : Possibilité de densification
- Croisement avec le GPU / PLU x MOS : Analyse croisant les ENAF en 2021 au MOS avec les PLU/PLUi/CC (déduction des zones de prescription) en zones U, AUc, AUs
- Cartes : Espaces NAF ayant connu un flux de consommation, consommation VS ENAF, nature des surfaces en 2021

Les cartographies concernant les données de l'OCS GE NG sont en développement.

<p align="center">
  <img src="https://raw.githubusercontent.com/geobretagne/visufoncier/main/documentation/images/map.png" alt="Explorer les données carto" width="600"/>
</p>
<p align="center"><em>Cartographies dans l'onglet "Cartes".</em></p>

Accédez aux outils complets de visualisations via GeoBretagne : [GeoBretagne MViewer](https://geobretagne.fr/mviewer/?config=/apps/mos/config.xml)
