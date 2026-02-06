# ClaudeBar

<p align="center">
  <img src="../assets/icons/claudebar-macOS-Dark-1024x1024@1x.png" alt="Icône ClaudeBar" width="128" height="128">
</p>

<p align="center">
  <strong>Une application native de barre de menu macOS pour surveiller les limites d'utilisation de Claude en temps réel.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="Licence">
</p>

<p align="center">
  <a href="../README.md">English</a> •
  <a href="README-TR.md">Türkçe</a> •
  <a href="README-ZH.md">中文</a> •
  <a href="README-HI.md">हिन्दी</a> •
  <a href="README-ES.md">Español</a> •
  <a href="README-FR.md">Français</a> •
  <a href="README-AR.md">العربية</a> •
  <a href="README-PT.md">Português</a> •
  <a href="README-JA.md">日本語</a> •
  <a href="README-RU.md">Русский</a> •
  <a href="README-IT.md">Italiano</a>
</p>

> **Note :** Cette traduction a été générée par IA et peut contenir des erreurs ou des inexactitudes. Soumettez une Pull Request pour les corrections.

---

## Fonctionnalités

- **Surveillance en Temps Réel** - Visualisez les limites de session et hebdomadaires d'un coup d'œil
- **Badge de Plan** - Affiche votre abonnement actuel (Pro, Max, Team)
- **Support d'Utilisation Extra** - Suivez les crédits à la demande lorsqu'ils sont activés
- **Barres de progression colorées** - Vert, jaune, orange, rouge selon le pourcentage d'utilisation
- **Support multilingue** - Anglais, turc, chinois, espagnol, russe avec sélecteur de langue intégré
- **Notifications Personnalisables** - Recevez des notifications à 50%, 75%, 100% ou lors de la réinitialisation
- **Rafraîchissement Automatique** - Intervalle de rafraîchissement configurable (30s, 1m, 2m, 5m)
- **Lancement au Démarrage** - Démarrez optionnellement avec votre Mac
- **Pourcentage dans la Barre de Menu** - Afficher/masquer le pourcentage à côté de l'icône
- **Expérience Native** - Construit avec SwiftUI, suit les directives de design macOS
- **Léger** - Empreinte minimale de ressources, pas d'Electron
- **Axé sur la Confidentialité** - Pas d'analytique, pas de télémétrie

## Captures d'Écran

<p align="center">
  <img src="../screenshots/app-screenshot.png" alt="Vue Générale de ClaudeBar" width="380">
</p>

<p align="center">
  <em>Surveillance en temps réel avec badge de plan</em>
</p>

<details>
<summary><strong>Plus de Captures d'Écran</strong></summary>

<br>

| Paramètres | Notifications | À propos |
|:----------:|:-------------:|:--------:|
| <img src="../screenshots/settings-screenshot.png" alt="Paramètres" width="250"> | <img src="../screenshots/notifications-screenshot.png" alt="Notifications" width="250"> | <img src="../screenshots/about-screenshot.png" alt="À propos" width="250"> |

</details>

## Prérequis

- macOS 14.0 (Sonoma) ou ultérieur
- [Claude Code](https://claude.ai/code) installé et connecté
- Abonnement actif Claude Pro, Max ou Team

## Installation

### Télécharger le Binaire Pré-compilé

Téléchargez le dernier `.app` depuis la page [Releases](https://github.com/kemalasliyuksek/claudebar/releases), puis faites-le glisser dans votre dossier Applications.

> **Note :** Si macOS affiche « ClaudeBar est endommagé et ne peut pas être ouvert », exécutez la commande suivante pour supprimer le drapeau de quarantaine :
> ```bash
> xattr -cr ClaudeBar.app
> ```

### Compiler depuis le Code Source

```bash
git clone https://github.com/kemalasliyuksek/claudebar.git
cd claudebar
./build.sh
```

Le bundle d'application sera créé dans `.build/release/ClaudeBar.app`.

Pour installer :
```bash
cp -r .build/release/ClaudeBar.app /Applications/
```

## Utilisation

1. Assurez-vous d'être connecté à Claude Code (la commande `claude` doit fonctionner dans le terminal)
2. Lancez ClaudeBar depuis Applications ou Spotlight
3. Cliquez sur l'icône de jauge dans votre barre de menu pour voir les limites d'utilisation

### Paramètres

Cliquez sur l'icône ⚙️ pour configurer :

| Paramètre | Description |
|-----------|-------------|
| Lancer au démarrage | Démarrer automatiquement lors de la connexion |
| Afficher % dans la barre de menu | Afficher le pourcentage à côté de l'icône |
| Langue | Choisir la langue de l'app (Système, English, Türkçe, 中文, Español, Русский) |
| Intervalle de rafraîchissement | Fréquence de récupération des données (30s - 5m) |
| Notifier à 50% | Envoyer une notification à 50% d'utilisation |
| Notifier à 75% | Envoyer une notification à 75% d'utilisation |
| Notifier à la limite | Envoyer une notification quand la limite est atteinte |
| Notifier à la réinitialisation | Envoyer une notification quand la limite se réinitialise |

### À propos

Cliquez sur l'icône ⓘ pour voir les informations de l'application, les crédits et les liens.

## Fonctionnement

ClaudeBar lit les identifiants OAuth du Trousseau macOS que Claude Code stocke lors de la connexion. Il interroge ensuite l'API Anthropic pour obtenir vos limites d'utilisation actuelles.

### Architecture

```
┌─────────────────┐                      ┌───────────────────────────┐
│                 │  Stocke les tokens   │                           │
│   Claude Code   │─────────────────────▶│     Trousseau macOS       │
│   (CLI login)   │                      │ "Claude Code-credentials" │
└─────────────────┘                      └───────────────────────────┘
                                                     │
                                                     │ Lit les tokens
                                                     ▼
┌─────────────────┐                      ┌───────────────────────────┐
│                 │ GET /api/oauth/usage │                           │
│  Anthropic API  │◀─────────────────────│        ClaudeBar          │
│                 │─────────────────────▶│                           │
└─────────────────┘  Données d'usage     └───────────────────────────┘
```

## Notes Importantes

### Accès au Trousseau

Au premier lancement, macOS peut vous demander d'autoriser ClaudeBar à accéder au Trousseau. Cliquez sur **Toujours Autoriser** pour un fonctionnement sans problème.

### Confidentialité

- Lit uniquement les identifiants existants du Trousseau
- Toute communication utilise HTTPS
- Aucune donnée stockée en dehors du Trousseau système
- Pas d'analytique ni de télémétrie
- Entièrement open source

## Contribuer

Les contributions sont les bienvenues ! N'hésitez pas à soumettre une Pull Request.

1. Forkez le dépôt
2. Créez votre branche de fonctionnalité (`git checkout -b feature/fonctionnalité-géniale`)
3. Commitez vos modifications (`git commit -m 'Ajouter fonctionnalité géniale'`)
4. Poussez vers la branche (`git push origin feature/fonctionnalité-géniale`)
5. Ouvrez une Pull Request

## Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](../LICENSE) pour les détails.

## Auteur

**Kemal Aslıyüksek** - [@kemalasliyuksek](https://github.com/kemalasliyuksek)

## Avertissement

Ceci est un projet communautaire non officiel et n'est pas affilié, officiellement maintenu ou approuvé par Anthropic. Utilisez-le à votre propre discrétion.
