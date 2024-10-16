# Tutoriel : Gestion et personnalisation du tableau de bord VisuFoncier

## 1. Connexion à l'instance Superset
Pour accéder à votre instance Superset et commencer à modifier le tableau de bord VisuFoncier :
- Ouvrez le lien de votre instance Superset : [VisuFoncier Superset](https://superset.geobretagne.fr)
- Connectez-vous avec vos identifiants. 

## 2. Gestion du tableau de bord

### 2.1 Modification de la mise en page
Une fois connecté, vous pouvez modifier la disposition des éléments dans votre tableau de bord :
- Allez dans "Edit Dashboard".
- Vous pouvez déplacer, redimensionner et réorganiser les widgets, graphiques et tableaux pour ajuster la présentation selon vos besoins.

> ⚠️ **Attention** : Il est possible de changer le titre d'un graphique à partir de la mise en page, mais cela ne se répercute pas dans le réel titre du graphique. Il est donc préférable d'effectuer le changement dans le menu "Charts".

### 2.2 Gestion du tableau de bord
Pour gérer le contenu du tableau de bord, vous avez accès à plusieurs options :
- **Ajout de graphiques** : Cliquez sur "Add Chart" pour intégrer un nouveau graphique basé sur vos données MOS ou OCSGE.
- **Ajout de widgets** : Cliquez sur "Layout elements" pour intégrer de nouveaux onglets, zones de texte, séparateur, titre.

> ⚠️ **Attention** : Un graphique ne peut être intégré qu'une seule fois dans un tableau de bord. Toutefois, il peut être utilisé dans plusieurs tableaux de bord différents. Si une modification est apportée au graphique, cette modification sera répercutée dans tous les tableaux de bord où le graphique est présent.

## 3. Gestion des données (datasets)

### 3.1 Description des datasets associés à l'outil Visufoncier
Les datasets utilisés proviennent du traitement des données MOS et OCS GE NG. Chaque graphique est lié à une table ou une vue matérialisée dans la base de données PostgreSQL :

**MOS** :

`mos_foncier_agrege_com`  
`mos_foncier_agrege_com_conso_view`  
`mos_foncier_agrege_com_temporel_view`  
`mos_foncier_agrege_nature2011_view`  
`mos_foncier_agrege_nature2021_det_tot_view`  
`mos_foncier_agrege_nature2021_det_view`  
`mos_foncier_agrege_com_liengeo_view`  
`mos_foncier_agrege_com_temporel_log_view`  
`mos_foncier_agrege_enaf_nature2021_det_view`  
`mos_foncier_agrege_nature2011_nature_2021_view`  
`mos_foncier_agrege_nature2021_det_densification_view`  
`mos_foncier_agrege_plu_view`  
`ff_mos_foncier_tup_view`  

**OCS GE** :

`ocsge_agrege_com_liengeo_view`  
`ocsge_code_cs_lib_artif_view`  
`ocsge_code_cs_lib_nonartif_view`  
`ocsge_code_cs_lib_view`  
`ocsge_code_us_lib_artif_view`  
`ocsge_code_us_lib_nonartif_view`  
`ocsge_code_us_lib_view`  
`ocsge_fluxartif_desartif_cs_us_view`  
`ocsge_fluxartif_desartif_net_view`  

>⚠️ **Attention** : Il est préférable d'avoir plusieurs vues matérialisées correspondant à un ou plusieurs graphiques, plutôt que d'avoir seulement une table de données reliée à tous les graphiques. Cela optimise l'affichage dans le tableau de bord. Il est également recommandé d'ajouter des index à vos données, notamment des index géographiques et des index sur les variables servant à filtrer.


### 3.2 Mise à jour des données
En cas de modification structurelle d'une table ou d'une vue matérialisée dans la base de données, il faudra actualiser le dataset modifié.
Dans l'onglet "columns", "Sync columns from source" :
<p align="center">
    <img src="https://github.com/geobretagne/visufoncier/blob/main/documentation/images/sync_data.png" alt="template_sql" width="500" />
</p>

En cas de suppression ou d'ajout de données dans la table ou la vue matérialisée dans la base de données, le dataset s'actualise automatiquement. 

### 3.3 Templating SQL
Pour générer des URLs dynamiques et personnaliser l'affichage, vous pouvez utiliser du templating SQL dans vos datasets :
Dans le menu modification d'un dataset, passer le dataset en virtuel "click the lock to make changes / virtual" puis ajouter le code SQL. 
<p align="center">
    <img src="https://github.com/geobretagne/visufoncier/blob/main/documentation/images/template_sql.png" alt="template_sql" width="500" />
</p>


Voici un exemple de requête SQL :

```sql
SELECT *
FROM visufoncier.ocsge_fluxartif_desartif_net_view
WHERE insee_com = '{{ url_param('insee') }}'
   OR '{{ url_param('insee') }}' = 'None';

```
Ici, l'URL est personnalisée avec le code insee correspondant à la variable insee_com.

## 4. Gestion des graphiques (charts)
Chaque graphique a un identifiant unique. Un graphique peut être intégré une seule fois dans un tableau de bord. Cependant, il est possible de dupliquer les graphiques en utilisant le menu "Save As...".
L'identifiant d'un graphique sera utilisé lors de la personnalisation (par exemple, pour effacer le titre d'un graphique) dans le code CSS.

## 5. Gestion des droits
Dans l'instance Superset, les droits d’accès peuvent être gérés au niveau des rôles utilisateurs. Pour attribuer ou modifier des droits :
- Allez dans "Settings" > "List Roles".
- Il est nécessaire de déclarer les datasets associés au tableau de bord dans le rôle public afin de publier la donnée avec "datasource access on" ou "schema access on". 

## 6. Gestion des filtres

### 6.1 Modification des filtres

Dans le tableau de bord, les filtres peuvent être modifiés dans le menu à gauche de l'écran, sous "Add/edit filters"
- Dans l'onglet "Settings" : 

<p align="center">
    <img src="https://github.com/geobretagne/visufoncier/blob/main/documentation/images/add_edit_filter.png" alt="template_sql" width="500" />
</p>

⚠️ **Attention** : Lorsqu'une variable de filtre a plus de 1000 valeurs possibles, il faut cocher l'option "Dynamically search all filter values". (Voir aussi la partie configuration dans `superset_config.py`.)

Il est possible de créer des dépendances entre les valeurs de filtres, des pré-filtres, des valeurs par défaut et d'obliger une valeur.

- Dans l'onglet "Scoping":

Il est possible d'appliquer les filtres seulement sur certaines parties du tableau de bord (onglets, graphiques).

*Indication : Pour les futures vagues de l'OCS GE et du MOS, les millésimes sont ajoutés en filtre mais appliqués à aucune partie du tableau de bord. Lors des prochaines vagues, il suffira d'ajouter ces filtres et de veiller à ce que toutes les tables ou vues contiennent les variables de filtre sur le millésime.*

### 6.2 Dans les datasets
Les filtres utilisés dans le tableau sont tous reliés aux vues matérialisées `ocsge_agrege_com_liengeo_view` pour l'OCS GE et `mos_foncier_agrege_com_liengeo_view` pour le MOS. Chaque variable utilisée dans les filtres doit se retrouver dans chaque table ou vue matérialisée utilisée dans le tableau de bord.

Par exemple, si la variable "nom_departement" est oubliée dans une vue matérialisée, le filtre département ne s'applique pas aux graphiques associés à cette vue.

## 7. Personnalisation

### 7.1 Personnalisation avec le CSS
L'apparence du tableau de bord (par exemple, ajuster la taille des polices ou les marges des éléments), est personnalisé avec du code CSS.
<p align="center">
    <img src="https://github.com/geobretagne/visufoncier/blob/main/documentation/images/css_editor.png" alt="template_sql" width="500" />
</p>

*Le code CSS est commenté et disponible dans la section github - CSS à venir*

### 7.2 Personnalisation avec le code de métadonnées JSON
Pour personnaliser des aspects visuels comme les couleurs des graphiques en fonction des libellés :
- Accédez à "Dashboard properties", advanced pour spécifier des couleurs spécifiques à certains labels (exemple : assigner une couleur spécifique aux flux d’artificialisation et désartificialisation).

<p align="center">
    <img src="https://github.com/geobretagne/visufoncier/blob/main/documentation/images/metajson.png" alt="template_sql" width="500" />
</p>

*Le code metadonnées JSON est commenté et disponbile dans la section github - metajson à venir*

---

