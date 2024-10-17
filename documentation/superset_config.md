# Configuration du fichier `superset_config.py`

Dans le cadre de l'instance Superset utilisée pour le tableau de bord **Visufoncier**, plusieurs configurations spécifiques sont nécessaires pour dépasser certaines limitations, optimiser les performances, et permettre la diffusion publique des données et des visualisations. Ce guide détaille ces configurations.

## 1. Augmenter la limite de taille pour le tableau de bord

Par défaut, Superset impose une limite sur la taille des tableaux de bord en termes de nombre de graphiques et de texte. Si cette limite est atteinte, vous ne pourrez plus ajouter de nouveaux graphiques ou modifier les onglets, même si le tableau de bord existant se charge correctement.

Pour étendre cette limite, vous devez modifier le fichier `superset_config.py` et ajouter la ligne suivante :

[Source](https://github.com/apache/superset/discussions/13629)

```python
SUPERSET_DASHBOARD_POSITION_DATA_LIMIT = 131070
```


## 2. Rendre le tableau de bord diffusable

Pour rendre le tableau de bord diffusable, ajoutez la ligne suivante dans `superset_config.py` :

[Source](https://github.com/apache/superset/issues/9807)

```python
PUBLIC_ROLE_LIKE_GAMMA = True
```

Cette ligne de configuration permet de cloner les permissions du rôle Gamma (qui a des droits de lecture étendus) au rôle Public. 
Il faut ensuite aller dans le menu Rôle dans l’interface Superset et modifier les rôles publics pour retirer les « menu access to … » et autres fonctions qui ne doivent pas être publiques. L’autorisation sur les datasets doit être ajoutée sur chaque dataset utilisé dans les tableaux de bord dans ce menu rôle public. 




## 3. Permettre la diffusion d’iframe

Pour permettre la diffusion d’iframe, ajoutez la configuration suivante :

[Source](https://github.com/apache/superset/discussions/27064)

```python
HTML_SANITIZATION_SCHEMA_EXTENSIONS = {
    "attributes": {
        "*": ["style", "className"],
        "iframe": ["src"]
    },
    "tagNames": ["style", "iframe"],
}
```

Maintenant, vous pouvez utiliser la balise iframe dans votre HTML, mais vous ne pouvez pas utiliser n'importe quel src. Pour utiliser un src spécifique, vous devez l’ajouter dans le CSP comme suit :

```python
"frame-src": [
    "'self'",
    "www.example_website.com",
],
```

## 4. Augmenter la limite de nombre de valeur dans les filtres

- **`ROW_LIMIT = 50000`**
  - **Description :** Limite par défaut du nombre de lignes à retourner lors de la demande de données pour des graphiques.
  - **Valeur :** 50 000 lignes.
  - **Utilisation :** Permet d'extraire un volume important de données pour la visualisation tout en évitant de surcharger le système.

- **`SAMPLES_ROW_LIMIT = 1000`**
  - **Description :** Limite par défaut du nombre d'échantillons à retourner lorsqu'une source de données est explorée dans la vue d'exploration.
  - **Valeur :** 1 000 lignes.
  - **Utilisation :** Fournit un aperçu des données sans engendrer des délais de chargement excessifs.

- **`NATIVE_FILTER_DEFAULT_ROW_LIMIT = 2000`**
  - **Description :** Limite par défaut du nombre de lignes pour les filtres natifs.
  - **Valeur :** 2 000 lignes.
  - **Utilisation :** Optimise les performances en restreignant le nombre de lignes disponibles pour le filtrage lors de l'application de filtres.

- **`FILTER_SELECT_ROW_LIMIT = 10000`**
  - **Description :** Nombre maximum de lignes récupérées pour l'auto-complétion des sélections de filtres.
  - **Valeur :** 10 000 lignes.
  - **Utilisation :** Affiche jusqu'à 10 000 suggestions de lignes pour aider l'utilisateur à affiner sa sélection lors de la saisie d'un filtre.

```python
# Limits
# Default row limit when requesting chart data
ROW_LIMIT = 50000

# Default row limit when requesting samples from datasource in explore view
SAMPLES_ROW_LIMIT = 1000

# Default row limit for native filters
NATIVE_FILTER_DEFAULT_ROW_LIMIT = 2000

# Max rows retrieved by filter select auto complete
FILTER_SELECT_ROW_LIMIT = 10000



```
## 5. Changer le format des nombres 

Pour obtenir l'affichage avec un espace entre les milliers et une virgule pour les décimales. 
- "decimal": "," : Cela indique que la virgule sera utilisée comme séparateur décimal.
- "thousands": " " : Cela spécifie que l'espace sera utilisé comme séparateur de milliers.
- "grouping": [3] : Cela signifie que le regroupement se fait par tranches de trois chiffres.
- "currency": ["", "€"] : Cela signifie que le symbole de la devise (dans ce cas, l'euro) sera affiché à la fin du nombre, sans espace entre le nombre et le symbole.

```python
# Format, see https://d3js.org/d3-format
D3_FORMAT = {
    "decimal": ",",
    "thousands": " ",
    "grouping": [3],
    "currency": ["", "€"]
}

```
