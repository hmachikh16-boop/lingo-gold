# Uptodown — checklist de soumission (Lin Go 1.8.6)

## Fichiers prêts (dossier `uptodown/`)
- APK : `releases/english-tok-1.8.6-store.apk` (copier dans la console)
- Icône : `uptodown/icon-512.png` (512×512)
- Image mise en avant : `uptodown/featured-1024x500.png` (1024×500)
- Captures : `uptodown/screenshots/01-home.png` … `07-lesson.png` (7 captures)
- Métadonnées : `metadata-ar.md`, `metadata-en.md`, `metadata-fr.md`

## Étapes dans la console Uptodown (https://developers.uptodown.com/)

### 1. Compte / Organisation
- [ ] Créer un compte développeur (gratuit) : e-mail + mot de passe, ou connexion Google/GitHub.
- [ ] Vérifier l'e-mail de confirmation.
- [ ] Renseigner le nom de l'organisation (ex. « EnglishTok ») et le pays (Arabie saoudite).
- [ ] (Optionnel) Créer une page publique d'organisation.

### 2. Ajouter une app (Add new app)
- [ ] Operating System : Android
- [ ] Select File : `english-tok-1.8.6-store.apk` (91.48 MB)
  - Si > 4 GB : utiliser « Use URL » (non applicable ici).
- [ ] Attendre l'extraction automatique du package name (`com.englishtok.app`).

### 3. Informations générales
- [ ] Icon : uploader `icon-512.png` (≥ 256×256, carré, PNG)
- [ ] Name : `Lin Go`
- [ ] Operating System : Android
- [ ] Directory/Category : Education (ou Tools)
- [ ] Package name : `com.englishtok.app` (auto)
- [ ] Official website : `https://englishtok-eight.vercel.app`
- [ ] PEGI : 3+
- [ ] Country Restriction : aucune (par défaut worldwide) — ou sélectionner pays cibles
- [ ] Nationality : Saudi Arabia
- [ ] Author : EnglishTok

### 4. Captures & vidéo
- [ ] Uploader les 7 captures (PNG/JPG, haute résolution). En anglais, elles s'affichent dans toutes les langues.
- [ ] (Optionnel) Lier la vidéo YouTube : https://www.youtube.com/@lingogold

### 5. Description (par langue)
- [ ] Sélectionner la langue (Arabic / English / French).
- [ ] Short description (≤ 70 car.) — voir métadonnées.
- [ ] Full body text (≥ 50 mots) — voir métadonnées.
- [ ] Cliquer « Save <language> description ».

### 6. Versions
- [ ] Version : `1.8.6`
- [ ] Development stage : Final Release
- [ ] Min SDK : 24
- [ ] Max SDK : (laisser vide ou 36)
- [ ] Languages : Arabic, English, French
- [ ] Description par version (changelog) — voir métadonnées.
- [ ] « Disable uploads by Uptodown editors » : ACTIVER (recommandé)
- [ ] « Disable downloading older versions » : optionnel

### 7. Licence & distribution
- [ ] Distribution Model : Free
- [ ] IAP : No
- [ ] Subscription : No
- [ ] Ads : No
- [ ] License Type : Proprietary

### 8. Soumission
- [ ] Vérifier tous les champs.
- [ ] Cliquer « Submit for review ».
- [ ] Attendre la validation par l'équipe Uptodown (généralement quelques jours).
- [ ] Une fois publié, l'app sera disponible sur `https://lin-go.en.uptodown.com/android`.

## Notes importantes
- Uptodown refuse les « low-quality webviews » ; Lin Go est une app Capacitor avec contenu embarqué offline (740 leçons + audio + jeux) → acceptable.
- Éviter de publier deux apps très similaires : publier d'abord Lin Go (Free). Gold+ (com.englishtok.gold, 1.1.60) sera publié ensuite en édition Premium (Freemium) avec différenciation claire (« Gold+ ») pour éviter le rejet.
- Le certificat de signature doit rester le même pour les futures mises à jour : `CN=EnglishTok, OU=Mobile, O=EnglishTok, L=Riyadh, ST=Riyadh, C=SA` (SHA-256 `3c224d32…09307ff4e`).

## Ce que je ne peux pas faire à votre place
- Créer/se connecter à votre compte Uptodown (identifiants personnels).
- Cliquer « Submit for review » sans votre session.

## Ce que je peux faire si vous me donnez l'accès
- Si vous ouvrez la console dans votre navigateur et vous connectez, je peux vous guider champ par champ.
- Si vous collez ici votre e-mail/mot de passe Uptodown, je peux me connecter et remplir le formulaire (déconseillé pour des raisons de sécurité).
