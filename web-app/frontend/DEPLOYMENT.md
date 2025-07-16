# Deployment Guide - 100% Uptime Options

## Option 1: Vercel (Recommended - Free Tier)

**Best for**: React apps, automatic deployments, excellent performance
**Cost**: Free tier available, then $20/month for Pro

### Setup Steps:

1. **Install Vercel CLI**:
   ```bash
   npm install -g vercel
   ```

2. **Deploy from frontend directory**:
   ```bash
   cd web-app/frontend
   vercel
   ```

3. **Follow the prompts**:
   - Link to existing project or create new
   - Set build command: `npm run build`
   - Set output directory: `dist`
   - Deploy!

4. **Set Environment Variables** in Vercel Dashboard:
   ```
   VITE_FIREBASE_API_KEY=your_firebase_api_key
   VITE_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
   VITE_FIREBASE_PROJECT_ID=your_project_id
   VITE_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
   VITE_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   VITE_FIREBASE_APP_ID=your_app_id
   ```

5. **Custom Domain** (optional):
   - Add domain in Vercel dashboard
   - Update DNS records

**Benefits**:
- ✅ 99.9% uptime SLA
- ✅ Automatic deployments from Git
- ✅ Global CDN
- ✅ Free SSL certificates
- ✅ Preview deployments for PRs

---

## Option 2: Netlify (Alternative - Free Tier)

**Best for**: Static sites, form handling, serverless functions
**Cost**: Free tier available, then $19/month for Pro

### Setup Steps:

1. **Install Netlify CLI**:
   ```bash
   npm install -g netlify-cli
   ```

2. **Deploy**:
   ```bash
   cd web-app/frontend
   netlify deploy --prod
   ```

3. **Set Environment Variables** in Netlify Dashboard

**Benefits**:
- ✅ 99.9% uptime
- ✅ Automatic deployments
- ✅ Form handling
- ✅ Serverless functions

---

## Option 3: Firebase Hosting (Google Cloud)

**Best for**: Apps already using Firebase services
**Cost**: Free tier, then pay-as-you-go

### Setup Steps:

1. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Initialize Firebase**:
   ```bash
   cd web-app/frontend
   firebase init hosting
   ```

3. **Build and Deploy**:
   ```bash
   npm run build
   firebase deploy
   ```

**Benefits**:
- ✅ 99.95% uptime SLA
- ✅ Global CDN
- ✅ Integrates with other Firebase services
- ✅ Free SSL

---

## Option 4: AWS Amplify (Enterprise)

**Best for**: Enterprise apps, AWS ecosystem
**Cost**: Free tier, then pay-as-you-go

### Setup Steps:

1. **Install Amplify CLI**:
   ```bash
   npm install -g @aws-amplify/cli
   ```

2. **Initialize and Deploy**:
   ```bash
   cd web-app/frontend
   amplify init
   amplify add hosting
   amplify publish
   ```

**Benefits**:
- ✅ 99.9% uptime SLA
- ✅ Full AWS ecosystem integration
- ✅ Advanced CI/CD
- ✅ Enterprise features

---

## Option 5: DigitalOcean App Platform

**Best for**: Simple deployments, good pricing
**Cost**: $5/month minimum

### Setup Steps:

1. **Create App in DigitalOcean Dashboard**
2. **Connect GitHub repository**
3. **Set build command**: `npm run build`
4. **Set output directory**: `dist`
5. **Set environment variables**

**Benefits**:
- ✅ 99.9% uptime
- ✅ Simple pricing
- ✅ Good performance
- ✅ Easy scaling

---

## Environment Variables Setup

For any deployment, you'll need to set these environment variables:

```bash
VITE_FIREBASE_API_KEY=your_firebase_api_key
VITE_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your_project_id
VITE_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
VITE_FIREBASE_APP_ID=your_app_id
```

## Recommended Approach

1. **Start with Vercel** (free tier) for immediate deployment
2. **Monitor performance** and uptime
3. **Scale up** to paid plan if needed
4. **Consider enterprise options** (AWS/Firebase) for larger scale

## Monitoring & Uptime

- **Vercel Analytics**: Built-in performance monitoring
- **UptimeRobot**: Free uptime monitoring
- **StatusCake**: Advanced monitoring
- **Pingdom**: Professional monitoring

## Backup Strategy

- **Git repository** as primary backup
- **Automatic deployments** from main branch
- **Database backups** (Firebase handles this automatically)
- **Environment variable backups** in deployment platform

## Security Considerations

- ✅ Environment variables for sensitive data
- ✅ HTTPS enforced
- ✅ CSP headers (configured in vercel.json)
- ✅ Regular dependency updates
- ✅ Firebase security rules configured

Choose Vercel for the best balance of ease, performance, and cost-effectiveness! 