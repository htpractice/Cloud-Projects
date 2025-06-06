# 🧪 Testing Strategy & Quality Assurance

## Current Testing Gaps

### 1. **No Automated Testing**
- No unit tests for application code
- No integration tests for API endpoints
- No end-to-end testing for user workflows

### 2. **Quality Assurance Issues**
- No code quality checks
- No static analysis or linting
- No vulnerability scanning

### 3. **Deployment Risk**
- No testing before production deployment
- No rollback strategy
- No performance testing

---

## 🎯 Comprehensive Testing Strategy

### 1. **Unit Testing Setup**

```javascript
// movie-app/server/tests/unit/movie.test.js
const request = require('supertest');
const app = require('../../index');
const Movie = require('../../models/Movie');

// Mock the Movie model
jest.mock('../../models/Movie');

describe('Movie API', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /api/movies', () => {
    it('should return all movies', async () => {
      const mockMovies = [
        { _id: '1', title: 'Test Movie 1', year: 2021 },
        { _id: '2', title: 'Test Movie 2', year: 2022 }
      ];

      Movie.find.mockResolvedValue(mockMovies);

      const response = await request(app).get('/api/movies');

      expect(response.status).toBe(200);
      expect(response.body).toEqual(mockMovies);
      expect(Movie.find).toHaveBeenCalledTimes(1);
    });

    it('should handle errors gracefully', async () => {
      Movie.find.mockRejectedValue(new Error('Database error'));

      const response = await request(app).get('/api/movies');

      expect(response.status).toBe(500);
      expect(response.body).toHaveProperty('error');
    });
  });

  describe('POST /api/movies', () => {
    it('should create a new movie', async () => {
      const newMovie = { title: 'New Movie', year: 2023 };
      const savedMovie = { _id: '3', ...newMovie };

      Movie.prototype.save = jest.fn().mockResolvedValue(savedMovie);

      const response = await request(app)
        .post('/api/movies')
        .send(newMovie);

      expect(response.status).toBe(201);
      expect(response.body).toEqual(savedMovie);
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/movies')
        .send({});

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });
  });
});
```

```json
// movie-app/server/package.json (testing dependencies)
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:ci": "jest --ci --coverage --watchAll=false"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "supertest": "^6.2.0",
    "@types/jest": "^29.0.0"
  },
  "jest": {
    "testEnvironment": "node",
    "coverageDirectory": "coverage",
    "collectCoverageFrom": [
      "**/*.js",
      "!node_modules/**",
      "!coverage/**",
      "!tests/**"
    ],
    "coverageThreshold": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    }
  }
}
```

### 2. **Frontend Testing with React Testing Library**

```javascript
// movie-app/client/src/components/__tests__/MovieCard.test.js
import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import MovieCard from '../MovieCard';

const mockMovie = {
  _id: '1',
  title: 'Test Movie',
  year: 2021,
  genre: 'Action',
  poster: 'test-poster.jpg'
};

describe('MovieCard', () => {
  it('renders movie information correctly', () => {
    render(<MovieCard movie={mockMovie} />);
    
    expect(screen.getByText('Test Movie')).toBeInTheDocument();
    expect(screen.getByText('2021')).toBeInTheDocument();
    expect(screen.getByText('Action')).toBeInTheDocument();
    expect(screen.getByAltText('Test Movie')).toBeInTheDocument();
  });

  it('calls onEdit when edit button is clicked', () => {
    const mockOnEdit = jest.fn();
    render(<MovieCard movie={mockMovie} onEdit={mockOnEdit} />);
    
    const editButton = screen.getByRole('button', { name: /edit/i });
    fireEvent.click(editButton);
    
    expect(mockOnEdit).toHaveBeenCalledWith(mockMovie);
  });

  it('calls onDelete when delete button is clicked', () => {
    const mockOnDelete = jest.fn();
    render(<MovieCard movie={mockMovie} onDelete={mockOnDelete} />);
    
    const deleteButton = screen.getByRole('button', { name: /delete/i });
    fireEvent.click(deleteButton);
    
    expect(mockOnDelete).toHaveBeenCalledWith(mockMovie._id);
  });
});
```

### 3. **Integration Tests**

```javascript
// movie-app/server/tests/integration/movie.integration.test.js
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../index');
const Movie = require('../../models/Movie');

describe('Movie Integration Tests', () => {
  beforeAll(async () => {
    // Connect to test database
    await mongoose.connect(process.env.MONGODB_TEST_URI);
  });

  beforeEach(async () => {
    // Clean database before each test
    await Movie.deleteMany({});
  });

  afterAll(async () => {
    await mongoose.connection.close();
  });

  describe('Movie CRUD Operations', () => {
    it('should create, read, update, and delete a movie', async () => {
      // Create
      const movieData = {
        title: 'Integration Test Movie',
        year: 2023,
        genre: 'Test Genre'
      };

      const createResponse = await request(app)
        .post('/api/movies')
        .send(movieData);

      expect(createResponse.status).toBe(201);
      expect(createResponse.body.title).toBe(movieData.title);
      const movieId = createResponse.body._id;

      // Read
      const readResponse = await request(app)
        .get(`/api/movies/${movieId}`);

      expect(readResponse.status).toBe(200);
      expect(readResponse.body.title).toBe(movieData.title);

      // Update
      const updateData = { title: 'Updated Movie Title' };
      const updateResponse = await request(app)
        .put(`/api/movies/${movieId}`)
        .send(updateData);

      expect(updateResponse.status).toBe(200);
      expect(updateResponse.body.title).toBe(updateData.title);

      // Delete
      const deleteResponse = await request(app)
        .delete(`/api/movies/${movieId}`);

      expect(deleteResponse.status).toBe(204);

      // Verify deletion
      const verifyResponse = await request(app)
        .get(`/api/movies/${movieId}`);

      expect(verifyResponse.status).toBe(404);
    });
  });
});
```

### 4. **End-to-End Testing with Cypress**

```javascript
// movie-app/cypress/e2e/movie-management.cy.js
describe('Movie Management', () => {
  beforeEach(() => {
    // Visit the app
    cy.visit('/');
    
    // Seed test data
    cy.task('seedDatabase');
  });

  afterEach(() => {
    // Clean up test data
    cy.task('cleanDatabase');
  });

  it('should display list of movies', () => {
    cy.get('[data-testid="movie-list"]').should('be.visible');
    cy.get('[data-testid="movie-card"]').should('have.length.at.least', 1);
  });

  it('should add a new movie', () => {
    cy.get('[data-testid="add-movie-button"]').click();
    
    cy.get('[data-testid="movie-title-input"]').type('Cypress Test Movie');
    cy.get('[data-testid="movie-year-input"]').type('2023');
    cy.get('[data-testid="movie-genre-input"]').type('Test');
    
    cy.get('[data-testid="save-movie-button"]').click();
    
    cy.get('[data-testid="movie-list"]')
      .should('contain', 'Cypress Test Movie');
  });

  it('should edit an existing movie', () => {
    cy.get('[data-testid="movie-card"]').first().as('firstMovie');
    cy.get('@firstMovie').find('[data-testid="edit-button"]').click();
    
    cy.get('[data-testid="movie-title-input"]')
      .clear()
      .type('Updated Movie Title');
    
    cy.get('[data-testid="save-movie-button"]').click();
    
    cy.get('[data-testid="movie-list"]')
      .should('contain', 'Updated Movie Title');
  });

  it('should delete a movie', () => {
    cy.get('[data-testid="movie-card"]').first().as('firstMovie');
    cy.get('@firstMovie').find('[data-testid="delete-button"]').click();
    
    cy.get('[data-testid="confirm-delete-button"]').click();
    
    // Verify movie is removed from the list
    cy.get('[data-testid="movie-list"]')
      .should('not.contain', 'Movie to be deleted');
  });
});
```

### 5. **Performance Testing with Artillery**

```yaml
# tests/performance/load-test.yml
config:
  target: 'http://localhost:3000'
  phases:
    - duration: 60
      arrivalRate: 10
      name: "Warm up"
    - duration: 120
      arrivalRate: 50
      name: "Ramp up load"
    - duration: 600
      arrivalRate: 100
      name: "Sustained load"

scenarios:
  - name: "Movie API Load Test"
    weight: 70
    flow:
      - get:
          url: "/api/movies"
      - think: 2
      - get:
          url: "/api/movies/{{ $randomString() }}"
      - think: 1
      - post:
          url: "/api/movies"
          json:
            title: "Load Test Movie {{ $randomString() }}"
            year: "{{ $randomInt(2000, 2023) }}"
            genre: "Action"

  - name: "Health Check"
    weight: 30
    flow:
      - get:
          url: "/health"
      - think: 1
```

### 6. **Security Testing**

```javascript
// tests/security/security.test.js
const request = require('supertest');
const app = require('../../server/index');

describe('Security Tests', () => {
  describe('Input Validation', () => {
    it('should prevent SQL injection attempts', async () => {
      const maliciousPayload = {
        title: "'; DROP TABLE movies; --",
        year: 2023
      };

      const response = await request(app)
        .post('/api/movies')
        .send(maliciousPayload);

      expect(response.status).toBe(400);
    });

    it('should prevent XSS attacks', async () => {
      const xssPayload = {
        title: '<script>alert("XSS")</script>',
        year: 2023
      };

      const response = await request(app)
        .post('/api/movies')
        .send(xssPayload);

      expect(response.status).toBe(400);
    });
  });

  describe('Authentication', () => {
    it('should require authentication for protected endpoints', async () => {
      const response = await request(app)
        .post('/api/admin/movies')
        .send({ title: 'Test', year: 2023 });

      expect(response.status).toBe(401);
    });
  });

  describe('Rate Limiting', () => {
    it('should implement rate limiting', async () => {
      const requests = [];
      
      // Make multiple requests rapidly
      for (let i = 0; i < 100; i++) {
        requests.push(request(app).get('/api/movies'));
      }

      const responses = await Promise.all(requests);
      const rateLimitedResponses = responses.filter(r => r.status === 429);
      
      expect(rateLimitedResponses.length).toBeGreaterThan(0);
    });
  });
});
```

### 7. **Enhanced Jenkins Pipeline with Testing**

```groovy
// jenkins/Jenkinsfile.with-testing
pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        NODE_ENV = 'test'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'devopsninja-project', 
                    url: 'https://github.com/htpractice/ht-practice-work.git'
            }
        }

        stage('Install Dependencies') {
            parallel {
                stage('Server Dependencies') {
                    steps {
                        dir('project/movie-app/server') {
                            sh 'npm ci'
                        }
                    }
                }
                stage('Client Dependencies') {
                    steps {
                        dir('project/movie-app/client') {
                            sh 'npm ci'
                        }
                    }
                }
            }
        }

        stage('Code Quality') {
            parallel {
                stage('Lint Server') {
                    steps {
                        dir('project/movie-app/server') {
                            sh 'npm run lint'
                        }
                    }
                }
                stage('Lint Client') {
                    steps {
                        dir('project/movie-app/client') {
                            sh 'npm run lint'
                        }
                    }
                }
                stage('Security Audit') {
                    steps {
                        dir('project/movie-app/server') {
                            sh 'npm audit --audit-level moderate'
                        }
                    }
                }
            }
        }

        stage('Unit Tests') {
            parallel {
                stage('Server Tests') {
                    steps {
                        dir('project/movie-app/server') {
                            sh 'npm run test:ci'
                        }
                    }
                    post {
                        always {
                            publishTestResults testResultsPattern: 'project/movie-app/server/junit.xml'
                            publishCoverage adapters: [
                                coberturaAdapter('project/movie-app/server/coverage/cobertura-coverage.xml')
                            ]
                        }
                    }
                }
                stage('Client Tests') {
                    steps {
                        dir('project/movie-app/client') {
                            sh 'npm run test:ci'
                        }
                    }
                    post {
                        always {
                            publishTestResults testResultsPattern: 'project/movie-app/client/junit.xml'
                        }
                    }
                }
            }
        }

        stage('Build Images') {
            steps {
                script {
                    dir('project/movie-app') {
                        sh '''
                            docker build -t movies-client:${BUILD_NUMBER} ./client
                            docker build -t movies-server:${BUILD_NUMBER} ./server
                        '''
                    }
                }
            }
        }

        stage('Integration Tests') {
            steps {
                script {
                    sh '''
                        docker-compose -f project/movie-app/docker-compose.test.yml up -d
                        sleep 30
                        docker-compose -f project/movie-app/docker-compose.test.yml exec -T server npm run test:integration
                    '''
                }
            }
            post {
                always {
                    sh 'docker-compose -f project/movie-app/docker-compose.test.yml down'
                }
            }
        }

        stage('Security Scanning') {
            parallel {
                stage('Container Scanning') {
                    steps {
                        script {
                            sh '''
                                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                                    aquasec/trivy image movies-server:${BUILD_NUMBER}
                                
                                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                                    aquasec/trivy image movies-client:${BUILD_NUMBER}
                            '''
                        }
                    }
                }
                stage('SAST Scan') {
                    steps {
                        sh '''
                            docker run --rm -v $(pwd):/src \
                                returntocorp/semgrep --config=auto project/movie-app/
                        '''
                    }
                }
            }
        }

        stage('Performance Tests') {
            when {
                branch 'main'
            }
            steps {
                script {
                    sh '''
                        docker-compose -f project/movie-app/docker-compose.test.yml up -d
                        sleep 30
                        npx artillery run tests/performance/load-test.yml
                    '''
                }
            }
            post {
                always {
                    sh 'docker-compose -f project/movie-app/docker-compose.test.yml down'
                    archiveArtifacts artifacts: 'artillery-report.json', allowEmptyArchive: true
                }
            }
        }

        stage('Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                script {
                    // Deploy to staging environment
                    sh '''
                        docker tag movies-client:${BUILD_NUMBER} ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/staging-movie-app-client-repo:${BUILD_NUMBER}
                        docker tag movies-server:${BUILD_NUMBER} ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/staging-movie-app-server-repo:${BUILD_NUMBER}
                        docker push ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/staging-movie-app-client-repo:${BUILD_NUMBER}
                        docker push ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/staging-movie-app-server-repo:${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('E2E Tests') {
            when {
                branch 'develop'
            }
            steps {
                script {
                    sh '''
                        cd project/movie-app
                        npx cypress run --env staging=true
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'project/movie-app/cypress/videos/**/*.mp4', allowEmptyArchive: true
                    archiveArtifacts artifacts: 'project/movie-app/cypress/screenshots/**/*.png', allowEmptyArchive: true
                }
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                script {
                    input message: 'Deploy to production?', ok: 'Deploy'
                    
                    sh '''
                        docker tag movies-client:${BUILD_NUMBER} ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/prod-movie-app-client-repo:${BUILD_NUMBER}
                        docker tag movies-server:${BUILD_NUMBER} ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/prod-movie-app-server-repo:${BUILD_NUMBER}
                        docker push ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/prod-movie-app-client-repo:${BUILD_NUMBER}
                        docker push ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/prod-movie-app-server-repo:${BUILD_NUMBER}
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            emailext (
                subject: "Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Build failed. Check console output at ${env.BUILD_URL}",
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
        }
        success {
            emailext (
                subject: "Build Successful: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Build completed successfully. Deploy is ready.",
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
        }
    }
}
```

---

## 📊 Testing Metrics & Reporting

### 1. **Coverage Goals**
- **Unit Tests**: 80% code coverage minimum
- **Integration Tests**: All API endpoints covered
- **E2E Tests**: All critical user journeys covered

### 2. **Quality Gates**
- All tests must pass before deployment
- Security vulnerabilities must be addressed
- Performance benchmarks must be met
- Code quality scores above threshold

### 3. **Reporting Dashboard**
- Test execution trends
- Coverage trends over time
- Defect density metrics
- Performance regression tracking

---

## 🚀 Implementation Roadmap

### Week 1: Foundation
- Set up unit testing frameworks
- Implement basic unit tests
- Configure code coverage reporting

### Week 2: Integration & E2E
- Set up integration test environment
- Implement API integration tests
- Set up Cypress for E2E testing

### Week 3: Security & Performance
- Implement security testing
- Set up performance testing with Artillery
- Configure vulnerability scanning

### Week 4: CI/CD Integration
- Integrate all tests into Jenkins pipeline
- Set up quality gates
- Configure automated reporting

---

## 💰 Tooling Costs

### Free Tools
- Jest (Unit testing)
- React Testing Library
- Cypress (Open source)
- Artillery (Performance testing)

### Paid Tools (Optional)
- Cypress Dashboard: ~$75/month
- Security scanning tools: ~$100/month
- Performance monitoring: ~$50/month

**Total Estimated Cost: $0–225/month (depending on scale)** 