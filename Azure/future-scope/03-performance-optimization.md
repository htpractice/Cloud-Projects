# Performance Optimization Guide

## ⚡ Overview

Transform the Azure static website into a high-performance, globally distributed solution with sub-second load times and optimal user experience worldwide.

## 📊 Current vs Target Performance

### Current Performance Metrics
- **Load Time**: 2-3 seconds (single region)
- **Time to First Byte (TTFB)**: 800-1200ms
- **Largest Contentful Paint (LCP)**: 2.5-4s
- **Cumulative Layout Shift (CLS)**: 0.1-0.25
- **First Input Delay (FID)**: 50-100ms
- **Global Coverage**: 1 region (East US)

### Target Performance Metrics
- **Load Time**: <500ms globally
- **Time to First Byte (TTFB)**: <200ms
- **Largest Contentful Paint (LCP)**: <2.5s
- **Cumulative Layout Shift (CLS)**: <0.1
- **First Input Delay (FID)**: <100ms
- **Global Coverage**: 50+ edge locations

## 🌐 Azure Front Door Implementation

### Enhanced Front Door Configuration

```bicep
// performance-frontdoor.bicep
resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: 'HighPerformanceFrontDoor'
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    originResponseTimeoutSeconds: 30
  }
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: frontDoorProfile
  name: 'performance-endpoint'
  location: 'Global'
  properties: {
    enabledState: 'Enabled'
  }
}

// Origin group with multiple origins for redundancy
resource originGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: frontDoorProfile
  name: 'static-website-origins'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 30
    }
  }
}

// Primary origin (Static Web App)
resource primaryOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: originGroup
  name: 'primary-staticwebapp'
  properties: {
    hostName: 'your-staticwebapp.azurestaticapps.net'
    httpPort: 80
    httpsPort: 443
    originHostHeader: 'your-staticwebapp.azurestaticapps.net'
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    sharedPrivateLinkResource: {}
  }
}

// Backup origin (Storage Account)
resource backupOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: originGroup
  name: 'backup-storage'
  properties: {
    hostName: 'yourstorageaccount.z13.web.core.windows.net'
    httpPort: 80
    httpsPort: 443
    originHostHeader: 'yourstorageaccount.z13.web.core.windows.net'
    priority: 2
    weight: 1000
    enabledState: 'Enabled'
  }
}

// Performance-optimized route
resource performanceRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: frontDoorEndpoint
  name: 'performance-route'
  properties: {
    originGroup: {
      id: originGroup.id
    }
    supportedProtocols: [
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
    cacheConfiguration: {
      queryStringCachingBehavior: 'IgnoreSpecifiedQueryStrings'
      queryParameters: 'utm_source,utm_medium,utm_campaign,fbclid'
      compressionSettings: {
        contentTypesToCompress: [
          'text/plain'
          'text/html'
          'text/css'
          'text/javascript'
          'application/javascript'
          'application/json'
          'application/xml'
          'text/xml'
          'image/svg+xml'
        ]
        isCompressionEnabled: true
      }
    }
  }
}
```

### Advanced Caching Rules

```bicep
// caching-rules.bicep
resource cacheRule 'Microsoft.Cdn/profiles/ruleSets@2023-05-01' = {
  parent: frontDoorProfile
  name: 'CachingRules'
}

// HTML files - short cache for dynamic content
resource htmlCacheRule 'Microsoft.Cdn/profiles/ruleSets/rules@2023-05-01' = {
  parent: cacheRule
  name: 'HtmlCaching'
  properties: {
    order: 1
    conditions: [
      {
        name: 'UrlFileExtension'
        parameters: {
          operator: 'Equal'
          negateCondition: false
          matchValues: ['html', 'htm']
          transforms: ['Lowercase']
          typeName: 'DeliveryRuleUrlFileExtensionMatchConditionParameters'
        }
      }
    ]
    actions: [
      {
        name: 'CacheExpiration'
        parameters: {
          cacheBehavior: 'Override'
          cacheType: 'All'
          cacheDuration: '00:05:00' // 5 minutes
          typeName: 'DeliveryRuleCacheExpirationActionParameters'
        }
      }
    ]
  }
}

// Static assets - long cache
resource staticAssetsCacheRule 'Microsoft.Cdn/profiles/ruleSets/rules@2023-05-01' = {
  parent: cacheRule
  name: 'StaticAssetsCaching'
  properties: {
    order: 2
    conditions: [
      {
        name: 'UrlFileExtension'
        parameters: {
          operator: 'Equal'
          negateCondition: false
          matchValues: ['css', 'js', 'png', 'jpg', 'jpeg', 'gif', 'svg', 'woff', 'woff2', 'ttf', 'eot', 'ico']
          transforms: ['Lowercase']
          typeName: 'DeliveryRuleUrlFileExtensionMatchConditionParameters'
        }
      }
    ]
    actions: [
      {
        name: 'CacheExpiration'
        parameters: {
          cacheBehavior: 'Override'
          cacheType: 'All'
          cacheDuration: '365.00:00:00' // 1 year
          typeName: 'DeliveryRuleCacheExpirationActionParameters'
        }
      }
      {
        name: 'ModifyResponseHeader'
        parameters: {
          headerAction: 'Overwrite'
          headerName: 'Cache-Control'
          value: 'public, max-age=31536000, immutable'
          typeName: 'DeliveryRuleHeaderActionParameters'
        }
      }
    ]
  }
}

// API responses - minimal cache
resource apiCacheRule 'Microsoft.Cdn/profiles/ruleSets/rules@2023-05-01' = {
  parent: cacheRule
  name: 'ApiCaching'
  properties: {
    order: 3
    conditions: [
      {
        name: 'UrlPath'
        parameters: {
          operator: 'BeginsWith'
          negateCondition: false
          matchValues: ['/api/']
          transforms: ['Lowercase']
          typeName: 'DeliveryRuleUrlPathMatchConditionParameters'
        }
      }
    ]
    actions: [
      {
        name: 'CacheExpiration'
        parameters: {
          cacheBehavior: 'Override'
          cacheType: 'All'
          cacheDuration: '00:01:00' // 1 minute
          typeName: 'DeliveryRuleCacheExpirationActionParameters'
        }
      }
    ]
  }
}
```

## 🚀 Asset Optimization

### Image Optimization Pipeline

```javascript
// build-scripts/optimize-images.js
const imagemin = require('imagemin');
const imageminWebp = require('imagemin-webp');
const imageminMozjpeg = require('imagemin-mozjpeg');
const imageminPngquant = require('imagemin-pngquant');
const imageminSvgo = require('imagemin-svgo');

async function optimizeImages() {
  console.log('Starting image optimization...');
  
  // Generate WebP versions
  await imagemin(['website/images/*.{jpg,jpeg,png}'], {
    destination: 'website/images/webp/',
    plugins: [
      imageminWebp({
        quality: 80,
        method: 6
      })
    ]
  });
  
  // Optimize JPEG images
  await imagemin(['website/images/*.{jpg,jpeg}'], {
    destination: 'website/images/optimized/',
    plugins: [
      imageminMozjpeg({
        quality: 85,
        progressive: true
      })
    ]
  });
  
  // Optimize PNG images
  await imagemin(['website/images/*.png'], {
    destination: 'website/images/optimized/',
    plugins: [
      imageminPngquant({
        quality: [0.6, 0.8]
      })
    ]
  });
  
  // Optimize SVG images
  await imagemin(['website/images/*.svg'], {
    destination: 'website/images/optimized/',
    plugins: [
      imageminSvgo({
        plugins: [
          { removeViewBox: false },
          { removeDimensions: true }
        ]
      })
    ]
  });
  
  console.log('Image optimization completed!');
}

optimizeImages().catch(console.error);
```

### CSS and JavaScript Optimization

```javascript
// build-scripts/optimize-assets.js
const CleanCSS = require('clean-css');
const UglifyJS = require('uglify-js');
const fs = require('fs').promises;
const path = require('path');

async function optimizeCSS() {
  const cssFiles = ['website/css/styles.css'];
  
  for (const file of cssFiles) {
    const css = await fs.readFile(file, 'utf8');
    const minified = new CleanCSS({
      level: 2,
      returnPromise: true
    }).minify(css);
    
    const outputPath = file.replace('.css', '.min.css');
    await fs.writeFile(outputPath, minified.styles);
    console.log(`CSS optimized: ${file} -> ${outputPath}`);
  }
}

async function optimizeJS() {
  const jsFiles = ['website/js/app.js'];
  
  for (const file of jsFiles) {
    const js = await fs.readFile(file, 'utf8');
    const minified = UglifyJS.minify(js, {
      compress: {
        drop_console: true,
        drop_debugger: true
      },
      mangle: true
    });
    
    if (minified.error) {
      console.error('JS minification error:', minified.error);
      continue;
    }
    
    const outputPath = file.replace('.js', '.min.js');
    await fs.writeFile(outputPath, minified.code);
    console.log(`JS optimized: ${file} -> ${outputPath}`);
  }
}

async function generateCriticalCSS() {
  const critical = require('critical');
  
  await critical.generate({
    inline: true,
    base: 'website/',
    src: 'index.html',
    dest: 'index-critical.html',
    width: 1300,
    height: 900,
    minify: true
  });
  
  console.log('Critical CSS generated');
}

module.exports = { optimizeCSS, optimizeJS, generateCriticalCSS };
```

## 📱 Progressive Web App (PWA) Implementation

### Service Worker for Caching

```javascript
// website/sw.js
const CACHE_NAME = 'azure-static-v1.0.0';
const urlsToCache = [
  '/',
  '/css/styles.min.css',
  '/js/app.min.js',
  '/images/optimized/logo.webp',
  '/manifest.json'
];

// Install event - cache resources
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('Opened cache');
        return cache.addAll(urlsToCache);
      })
      .then(() => {
        return self.skipWaiting();
      })
  );
});

// Fetch event - serve from cache with network fallback
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        // Return cached version or fetch from network
        if (response) {
          return response;
        }
        
        return fetch(event.request).then((response) => {
          // Check if valid response
          if (!response || response.status !== 200 || response.type !== 'basic') {
            return response;
          }
          
          // Clone response for cache
          const responseToCache = response.clone();
          
          caches.open(CACHE_NAME)
            .then((cache) => {
              cache.put(event.request, responseToCache);
            });
          
          return response;
        });
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      return self.clients.claim();
    })
  );
});
```

### Enhanced Web App Manifest

```json
{
  "name": "Azure Static Website",
  "short_name": "AzureStatic",
  "description": "High-performance static website hosted on Azure",
  "start_url": "/",
  "display": "standalone",
  "orientation": "portrait-primary",
  "background_color": "#0078d4",
  "theme_color": "#0078d4",
  "lang": "en-US",
  "scope": "/",
  "categories": ["business", "productivity"],
  "shortcuts": [
    {
      "name": "About",
      "short_name": "About",
      "description": "Learn about our Azure infrastructure",
      "url": "/about",
      "icons": [{ "src": "/images/icons/about-96.png", "sizes": "96x96" }]
    }
  ],
  "icons": [
    {
      "src": "/images/icons/icon-72.png",
      "sizes": "72x72",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/images/icons/icon-96.png",
      "sizes": "96x96",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/images/icons/icon-128.png",
      "sizes": "128x128",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/images/icons/icon-144.png",
      "sizes": "144x144",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/images/icons/icon-152.png",
      "sizes": "152x152",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/images/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/images/icons/icon-384.png",
      "sizes": "384x384",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/images/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable any"
    }
  ]
}
```

## ⚡ Performance Monitoring

### Real User Monitoring (RUM)

```javascript
// website/js/performance-monitoring.js
class PerformanceMonitor {
  constructor() {
    this.metrics = {};
    this.init();
  }
  
  init() {
    // Core Web Vitals monitoring
    this.observeLCP();
    this.observeFID();
    this.observeCLS();
    this.observeTTFB();
    
    // Custom metrics
    this.measureResourceTiming();
    this.measureNavigationTiming();
  }
  
  observeLCP() {
    const observer = new PerformanceObserver((list) => {
      const entries = list.getEntries();
      const lastEntry = entries[entries.length - 1];
      
      this.metrics.lcp = lastEntry.startTime;
      this.sendMetric('lcp', lastEntry.startTime);
    });
    
    observer.observe({ entryTypes: ['largest-contentful-paint'] });
  }
  
  observeFID() {
    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        this.metrics.fid = entry.processingStart - entry.startTime;
        this.sendMetric('fid', this.metrics.fid);
      }
    });
    
    observer.observe({ entryTypes: ['first-input'] });
  }
  
  observeCLS() {
    let clsScore = 0;
    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        if (!entry.hadRecentInput) {
          clsScore += entry.value;
        }
      }
      
      this.metrics.cls = clsScore;
      this.sendMetric('cls', clsScore);
    });
    
    observer.observe({ entryTypes: ['layout-shift'] });
  }
  
  observeTTFB() {
    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        this.metrics.ttfb = entry.responseStart - entry.requestStart;
        this.sendMetric('ttfb', this.metrics.ttfb);
      }
    });
    
    observer.observe({ entryTypes: ['navigation'] });
  }
  
  async sendMetric(name, value) {
    try {
      await fetch('/api/metrics', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          metric: name,
          value: value,
          timestamp: Date.now(),
          userAgent: navigator.userAgent,
          url: location.href
        })
      });
    } catch (error) {
      console.warn('Failed to send metric:', error);
    }
  }
}

// Initialize performance monitoring
if (typeof window !== 'undefined') {
  new PerformanceMonitor();
}
```

## 📊 Performance Testing

### Load Testing with Azure Load Testing

```yaml
# load-test-config.yaml
testName: "Azure Static Website Load Test"
engineInstances: 5
testDuration: "5m"
rampUpTime: "1m"

scenarios:
  - scenarioName: "Homepage Load Test"
    requests:
      - requestName: "GET Homepage"
        method: "GET"
        url: "https://your-domain.com/"
        headers:
          User-Agent: "LoadTest/1.0"
        
  - scenarioName: "Asset Load Test"
    weight: 30
    requests:
      - requestName: "GET CSS"
        method: "GET"
        url: "https://your-domain.com/css/styles.min.css"
      - requestName: "GET JS"
        method: "GET"
        url: "https://your-domain.com/js/app.min.js"
      - requestName: "GET Images"
        method: "GET"
        url: "https://your-domain.com/images/optimized/hero.webp"

thresholds:
  - metric: "response_time_p95"
    threshold: 500
    action: "stop"
  - metric: "error_rate"
    threshold: 1
    action: "stop"
```

## 💰 Performance Cost Analysis

### Cost vs Performance Trade-offs

| Performance Level | Monthly Cost | Load Time | Features |
|-------------------|--------------|-----------|----------|
| **Basic** | $2-5 | 2-3s | Storage hosting only |
| **Standard** | $25-50 | 800ms-1.2s | Front Door Standard + Static Web Apps |
| **Premium** | $50-100 | 200-500ms | Front Door Premium + Advanced caching |
| **Enterprise** | $100-200 | <200ms | Premium + Advanced monitoring + Load testing |

## 🎯 Performance Optimization Roadmap

### Week 1: Foundation
- [ ] Deploy Azure Front Door with basic configuration
- [ ] Implement asset optimization pipeline
- [ ] Configure basic caching rules
- [ ] Set up performance monitoring

### Week 2: Advanced Features
- [ ] Implement service worker and PWA features
- [ ] Deploy advanced caching strategies
- [ ] Configure multi-origin redundancy
- [ ] Set up real user monitoring

### Week 3: Optimization
- [ ] Fine-tune caching rules based on analytics
- [ ] Implement advanced compression
- [ ] Optimize critical rendering path
- [ ] Set up automated performance testing

## 📈 Expected Performance Improvements

| Metric | Before | After | Improvement |
|--------|--------|--------|-------------|
| **Load Time** | 2-3s | <500ms | 75-85% faster |
| **TTFB** | 800-1200ms | <200ms | 75-85% faster |
| **LCP** | 2.5-4s | <2.5s | 20-40% better |
| **Global Reach** | 1 region | 50+ PoPs | 5000% expansion |
| **Cache Hit Ratio** | 0% | 85-95% | Massive bandwidth savings |
| **Bandwidth Costs** | 100% origin | 5-15% origin | 85-95% reduction |

---

**Performance Investment**: $50-100/month  
**Load Time Improvement**: 75-85% faster globally  
**User Experience**: Significantly enhanced  
**SEO Benefits**: Better Core Web Vitals scores  
**Business Impact**: Higher conversion rates 