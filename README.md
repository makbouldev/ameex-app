# Ameex Logistics Suite 🚚📦

> **More than a delivery, an Ameexceptional experience.**  
> Application logistique complète pour la gestion des livraisons, des chauffeurs et du suivi GPS en temps réel à travers le Maroc (Ameex Express Logistics).

---

## 🌟 Fonctionnalités Clés

### 👨‍💼 1. Portail Administrateur (Admin Portal)
* **Tableau de bord interactif** : Statistiques en temps réel (Total commandes, En transit, Livrées, En attente).
* **Gestion des Commandes** : Création avec calcul automatique des gains livreurs, affectation intelligente, et génération de numéros de suivi (`AMX...`).
* **Numéro de Colis & Scanner Code-barres** : Saisie et numérisation instantanée des étiquettes codes-barres physiques (`CLS-...`).
* **Affectation avec Photos de Profil** : Sélection visuelle du livreur avec son portrait, son véhicule et sa zone.
* **Supervision GPS en Direct** : Carte OpenStreetMap avec la position en temps réel de tous les livreurs et des destinations clients pointées.
* **Validation de Remise à l'Agence** : Bouton d'action pour confirmer la prise en charge physique du colis par le livreur au hub agence.

### 🛵 2. Application Livreur (Driver App)
* **Workflow en 3 Étapes Sécurisées** :
  1. *Acceptation de la mission* : Notification de la commande assignée.
  2. *Récupération au Hub Agence* : Direction l'agence Ameex pour récupérer le paquet avec confirmation de remise.
  3. *Pointage précis du Client & Navigation* : Sélection ou recherche de l'adresse client sur la carte OSM, traçage dynamique de l'itinéraire et calcul télémétrique en direct (vitesse km/h, distance restante, temps estimé).
* **Scanner & Vérification du Colis** : Possibilité de scanner le code-barres du colis avant livraison pour éviter toute erreur de paquet.
* **Garantie Rémunération Ameex (> 50%)** : Si une commande est annulée après avoir dépassé 50% du trajet, le livreur conserve l'intégralité de sa rémunération (frais carburant et temps indemnisés).
* **Gestion des Revenus & Profil** : Historique des gains nets, statut en ligne/hors ligne et profil personnalisé.

### 🎨 3. Design & Expérience Utilisateur
* **Charte Graphique Officielle Ameex** : Bleu Royal Ameex (`#14307A`), Midnight Navy (`#04205F`), typographie *Plus Jakarta Sans*.
* **Animations Fluides (`AmeexAnimations`)** : Transitions de pages incurvées (`Curves.easeOutCubic`), navigation entre onglets sans rechargement de carte (`AnimatedIndexedStack`), et retours haptiques tactiles (`AmeexPressable`).

---

## 🛠️ Stack Technique

* **Framework** : [Flutter 3.x](https://flutter.dev) (Multi-plateforme : Web, Android, iOS, Desktop)
* **Cartographie** : OpenStreetMap via `flutter_map` & `latlong2` (100% Indépendant et gratuit, sans API payante Google Maps)
* **Backend & Données** : [Supabase](https://supabase.com) (PostgreSQL, Authentification, Realtime Streams)
* **Positionnement GPS** : `geolocator` avec fallback IP

---

## 🚀 Installation & Lancement

```bash
# 1. Cloner le dépôt
git clone https://github.com/makbouldev/ameex-app.git
cd ameex-app

# 2. Installer les dépendances
flutter pub get

# 3. Lancer en local (Web ou Mobile)
flutter run -d chrome
```

---

## 🔐 Identifiants de Test

| Rôle | Email | Mot de passe |
| :--- | :--- | :--- |
| **Administrateur** | `admin@ameex.ma` | `admin123456` |
| **Livreur Ameex** | `driver@ameex.ma` | `driver123456` |
