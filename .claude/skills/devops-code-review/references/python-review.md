# Python Code Review Guidelines for DevOps

## Python Best Practices

### 1. Code Structure and Imports

```python
# GOOD - Organized imports (PEP 8)
"""
Module for deploying applications to Kubernetes.

This module provides functions for building, pushing, and deploying
containerized applications to Kubernetes clusters.
"""

# Standard library imports
import os
import sys
import logging
from pathlib import Path
from typing import List, Dict, Optional

# Third-party imports
import requests
import yaml
from kubernetes import client, config

# Local imports
from .utils import validate_config
from .exceptions import DeploymentError

# Constants
DEFAULT_TIMEOUT = 300
MAX_RETRIES = 3

# BAD - Disorganized imports
from kubernetes import client
import os
from .utils import validate_config
import sys
import requests
```

### 2. Error Handling

```python
# GOOD - Specific exception handling
def deploy_service(service_name: str, namespace: str) -> bool:
    """Deploy a service to Kubernetes."""
    try:
        api = client.AppsV1Api()
        deployment = api.read_namespaced_deployment(service_name, namespace)

    except client.exceptions.ApiException as e:
        if e.status == 404:
            logger.error(f"Deployment {service_name} not found in {namespace}")
        else:
            logger.error(f"API error: {e.reason}")
        return False

    except Exception as e:
        logger.exception(f"Unexpected error deploying {service_name}")
        return False

    return True

# BAD - Bare except
def deploy_service(service_name, namespace):
    try:
        api = client.AppsV1Api()
        deployment = api.read_namespaced_deployment(service_name, namespace)
    except:  # Catches everything, including KeyboardInterrupt
        print("Error")
        return False

# BAD - Too broad exception
def deploy_service(service_name, namespace):
    try:
        api = client.AppsV1Api()
        deployment = api.read_namespaced_deployment(service_name, namespace)
    except Exception:  # Too broad
        return False
```

### 3. Resource Management

```python
# GOOD - Context managers for resources
def process_config(config_file: Path) -> Dict:
    """Load and process configuration file."""
    with open(config_file) as f:
        config = yaml.safe_load(f)

    return process_data(config)

# GOOD - Custom context manager
from contextlib import contextmanager

@contextmanager
def kubernetes_client(kubeconfig: Optional[str] = None):
    """Context manager for Kubernetes client."""
    if kubeconfig:
        config.load_kube_config(config_file=kubeconfig)
    else:
        config.load_incluster_config()

    api = client.CoreV1Api()
    try:
        yield api
    finally:
        # Cleanup if needed
        pass

# Usage
with kubernetes_client() as api:
    pods = api.list_namespaced_pod("default")

# BAD - No resource cleanup
def process_config(config_file):
    f = open(config_file)
    config = yaml.safe_load(f)
    # File never closed
    return config
```

### 4. Type Hints and Documentation

```python
# GOOD - Type hints and docstrings
from typing import List, Dict, Optional
from pathlib import Path

def deploy_application(
    app_name: str,
    version: str,
    namespace: str = "default",
    replicas: int = 3,
    env_vars: Optional[Dict[str, str]] = None
) -> bool:
    """
    Deploy an application to Kubernetes.

    Args:
        app_name: Name of the application to deploy
        version: Version tag for the container image
        namespace: Kubernetes namespace (default: "default")
        replicas: Number of replicas (default: 3)
        env_vars: Optional environment variables

    Returns:
        True if deployment successful, False otherwise

    Raises:
        DeploymentError: If deployment fails
        ValueError: If invalid parameters provided

    Example:
        >>> deploy_application("myapp", "v1.2.3", replicas=5)
        True
    """
    if replicas < 1:
        raise ValueError("Replicas must be at least 1")

    env_vars = env_vars or {}

    # Implementation
    return True

# BAD - No type hints or documentation
def deploy_application(app_name, version, namespace="default", replicas=3, env_vars=None):
    if replicas < 1:
        raise ValueError("Replicas must be at least 1")
    env_vars = env_vars or {}
    return True
```

### 5. Configuration and Secrets

```python
# GOOD - Environment-based configuration
import os
from dataclasses import dataclass
from typing import Optional

@dataclass
class Config:
    """Application configuration."""
    db_host: str
    db_port: int
    db_name: str
    api_key: str
    log_level: str = "INFO"

    @classmethod
    def from_env(cls) -> "Config":
        """Load configuration from environment variables."""
        return cls(
            db_host=os.environ["DB_HOST"],
            db_port=int(os.environ.get("DB_PORT", "5432")),
            db_name=os.environ["DB_NAME"],
            api_key=os.environ["API_KEY"],
            log_level=os.environ.get("LOG_LEVEL", "INFO")
        )

    def validate(self) -> None:
        """Validate configuration."""
        if not self.db_host:
            raise ValueError("DB_HOST cannot be empty")
        if not 1 <= self.db_port <= 65535:
            raise ValueError(f"Invalid DB_PORT: {self.db_port}")

# Usage
config = Config.from_env()
config.validate()

# BAD - Hardcoded secrets
DB_PASSWORD = "hardcoded_password"
API_KEY = "sk-1234567890"

# BAD - Secrets in code
def connect_db():
    return psycopg2.connect(
        host="localhost",
        password="my_password"  # Never do this
    )
```

### 6. Logging

```python
# GOOD - Structured logging
import logging
import json
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def deploy_service(service: str, version: str) -> bool:
    """Deploy a service."""
    logger.info(
        "Starting deployment",
        extra={
            "service": service,
            "version": version,
            "timestamp": datetime.utcnow().isoformat()
        }
    )

    try:
        # Deployment logic
        result = perform_deployment(service, version)

        logger.info(
            "Deployment successful",
            extra={"service": service, "version": version}
        )
        return True

    except Exception as e:
        logger.exception(
            "Deployment failed",
            extra={
                "service": service,
                "version": version,
                "error": str(e)
            }
        )
        return False

# BAD - Print statements
def deploy_service(service, version):
    print(f"Deploying {service}")  # Not configurable, no levels
    try:
        perform_deployment(service, version)
        print("Success")
    except Exception as e:
        print(f"Error: {e}")  # No stack trace

# BAD - Logging sensitive data
logger.info(f"Connecting with password: {password}")  # Never log secrets
```

### 7. Testing and Testability

```python
# GOOD - Testable code with dependency injection
from typing import Protocol

class KubernetesClient(Protocol):
    """Protocol for Kubernetes client."""
    def create_deployment(self, name: str, namespace: str) -> bool:
        ...

class DeploymentService:
    """Service for managing deployments."""

    def __init__(self, k8s_client: KubernetesClient):
        self.k8s_client = k8s_client

    def deploy(self, name: str, namespace: str = "default") -> bool:
        """Deploy application."""
        return self.k8s_client.create_deployment(name, namespace)

# Easy to test with mock
def test_deploy():
    mock_client = MockKubernetesClient()
    service = DeploymentService(mock_client)
    assert service.deploy("myapp") == True

# BAD - Hard to test
def deploy(name, namespace="default"):
    # Direct dependency on Kubernetes
    api = client.AppsV1Api()
    return api.create_namespaced_deployment(name, namespace)
```

### 8. Async/Await for I/O Operations

```python
# GOOD - Async for concurrent I/O
import asyncio
import aiohttp
from typing import List, Dict

async def fetch_metrics(url: str) -> Dict:
    """Fetch metrics from a URL."""
    async with aiohttp.ClientSession() as session:
        async with session.get(url, timeout=30) as response:
            return await response.json()

async def check_all_services(services: List[str]) -> List[Dict]:
    """Check health of all services concurrently."""
    tasks = [
        fetch_metrics(f"http://{service}/metrics")
        for service in services
    ]
    return await asyncio.gather(*tasks, return_exceptions=True)

# Usage
services = ["service1:8080", "service2:8080", "service3:8080"]
results = asyncio.run(check_all_services(services))

# BAD - Sequential blocking I/O
import requests

def check_all_services(services):
    results = []
    for service in services:
        response = requests.get(f"http://{service}/metrics")
        results.append(response.json())
    return results
```

### 9. Data Classes and Validation

```python
# GOOD - Use dataclasses with validation
from dataclasses import dataclass, field
from typing import List, Optional
from datetime import datetime

@dataclass
class Deployment:
    """Kubernetes deployment configuration."""
    name: str
    namespace: str
    image: str
    replicas: int = 3
    env_vars: Dict[str, str] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.utcnow)

    def __post_init__(self):
        """Validate after initialization."""
        if self.replicas < 1:
            raise ValueError("Replicas must be at least 1")
        if not self.name:
            raise ValueError("Name cannot be empty")
        if not self.image:
            raise ValueError("Image cannot be empty")

    def to_k8s_manifest(self) -> Dict:
        """Convert to Kubernetes manifest."""
        return {
            "apiVersion": "apps/v1",
            "kind": "Deployment",
            "metadata": {"name": self.name, "namespace": self.namespace},
            "spec": {
                "replicas": self.replicas,
                "template": {
                    "spec": {
                        "containers": [{
                            "name": self.name,
                            "image": self.image,
                            "env": [
                                {"name": k, "value": v}
                                for k, v in self.env_vars.items()
                            ]
                        }]
                    }
                }
            }
        }

# BAD - Dictionary with no validation
def create_deployment(name, namespace, image, replicas=3):
    return {
        "name": name,
        "namespace": namespace,
        "image": image,
        "replicas": replicas
    }
```

### 10. Command-Line Interface

```python
# GOOD - Use argparse or click
import argparse
import sys
from pathlib import Path

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Deploy applications to Kubernetes"
    )
    parser.add_argument(
        "app_name",
        help="Name of the application to deploy"
    )
    parser.add_argument(
        "--version",
        required=True,
        help="Version tag for the container image"
    )
    parser.add_argument(
        "--namespace",
        default="default",
        help="Kubernetes namespace (default: default)"
    )
    parser.add_argument(
        "--replicas",
        type=int,
        default=3,
        help="Number of replicas (default: 3)"
    )
    parser.add_argument(
        "--config",
        type=Path,
        help="Path to configuration file"
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose logging"
    )

    args = parser.parse_args()

    # Configure logging
    log_level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(level=log_level)

    # Validate
    if args.replicas < 1:
        parser.error("Replicas must be at least 1")

    # Execute
    try:
        deploy_application(
            args.app_name,
            args.version,
            args.namespace,
            args.replicas
        )
    except Exception as e:
        logger.exception("Deployment failed")
        sys.exit(1)

if __name__ == "__main__":
    main()

# BAD - Manual argument parsing
def main():
    if len(sys.argv) < 3:
        print("Usage: deploy.py <app> <version>")
        sys.exit(1)

    app = sys.argv[1]
    version = sys.argv[2]
    deploy_application(app, version)
```

## Python DevOps Patterns

### 1. Retry Logic with Exponential Backoff

```python
import time
from functools import wraps
from typing import Callable, Type

def retry(
    max_attempts: int = 3,
    delay: float = 1.0,
    backoff: float = 2.0,
    exceptions: tuple = (Exception,)
):
    """Retry decorator with exponential backoff."""
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            attempt = 0
            current_delay = delay

            while attempt < max_attempts:
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    attempt += 1
                    if attempt >= max_attempts:
                        raise

                    logger.warning(
                        f"Attempt {attempt} failed: {e}. "
                        f"Retrying in {current_delay}s..."
                    )
                    time.sleep(current_delay)
                    current_delay *= backoff

        return wrapper
    return decorator

# Usage
@retry(max_attempts=5, delay=1.0, backoff=2.0)
def call_api(url: str) -> Dict:
    response = requests.get(url, timeout=30)
    response.raise_for_status()
    return response.json()
```

### 2. Health Checks

```python
from enum import Enum
from dataclasses import dataclass
from typing import List, Callable

class HealthStatus(Enum):
    """Health check status."""
    HEALTHY = "healthy"
    UNHEALTHY = "unhealthy"
    DEGRADED = "degraded"

@dataclass
class HealthCheck:
    """Health check result."""
    name: str
    status: HealthStatus
    message: str = ""

class HealthChecker:
    """Perform health checks."""

    def __init__(self):
        self.checks: List[Callable] = []

    def register(self, check: Callable):
        """Register a health check."""
        self.checks.append(check)

    def run_all(self) -> List[HealthCheck]:
        """Run all health checks."""
        results = []
        for check in self.checks:
            try:
                result = check()
                results.append(result)
            except Exception as e:
                results.append(HealthCheck(
                    name=check.__name__,
                    status=HealthStatus.UNHEALTHY,
                    message=str(e)
                ))
        return results

    def is_healthy(self) -> bool:
        """Check if all checks are healthy."""
        results = self.run_all()
        return all(r.status == HealthStatus.HEALTHY for r in results)

# Usage
checker = HealthChecker()

@checker.register
def check_database() -> HealthCheck:
    try:
        db.execute("SELECT 1")
        return HealthCheck("database", HealthStatus.HEALTHY)
    except Exception as e:
        return HealthCheck("database", HealthStatus.UNHEALTHY, str(e))

@checker.register
def check_redis() -> HealthCheck:
    try:
        redis_client.ping()
        return HealthCheck("redis", HealthStatus.HEALTHY)
    except Exception as e:
        return HealthCheck("redis", HealthStatus.UNHEALTHY, str(e))
```

### 3. Metrics Collection

```python
from prometheus_client import Counter, Histogram, Gauge
import time
from functools import wraps

# Define metrics
deployment_counter = Counter(
    'deployments_total',
    'Total number of deployments',
    ['service', 'status']
)

deployment_duration = Histogram(
    'deployment_duration_seconds',
    'Deployment duration in seconds',
    ['service']
)

active_deployments = Gauge(
    'active_deployments',
    'Number of active deployments'
)

def track_deployment(func):
    """Decorator to track deployment metrics."""
    @wraps(func)
    def wrapper(service: str, *args, **kwargs):
        active_deployments.inc()
        start_time = time.time()

        try:
            result = func(service, *args, **kwargs)
            deployment_counter.labels(service=service, status='success').inc()
            return result

        except Exception as e:
            deployment_counter.labels(service=service, status='failure').inc()
            raise

        finally:
            duration = time.time() - start_time
            deployment_duration.labels(service=service).observe(duration)
            active_deployments.dec()

    return wrapper

@track_deployment
def deploy_service(service: str, version: str) -> bool:
    # Deployment logic
    return True
```

## Python Code Review Checklist

### Code Quality
- [ ] PEP 8 compliant (use black, flake8)
- [ ] Type hints for function signatures
- [ ] Docstrings for modules, classes, functions
- [ ] No unused imports or variables
- [ ] Consistent naming conventions

### Error Handling
- [ ] Specific exception handling
- [ ] No bare except clauses
- [ ] Proper error logging
- [ ] Resource cleanup (context managers)
- [ ] Meaningful error messages

### Security
- [ ] No hardcoded secrets
- [ ] Input validation
- [ ] SQL parameterization
- [ ] Safe deserialization
- [ ] Secure random generation

### Performance
- [ ] Async for I/O operations
- [ ] Generators for large datasets
- [ ] Appropriate data structures
- [ ] No N+1 queries
- [ ] Connection pooling

### Testing
- [ ] Unit tests present
- [ ] Testable design (dependency injection)
- [ ] Mock external dependencies
- [ ] Test coverage > 80%

### DevOps Specific
- [ ] Configuration externalized
- [ ] Structured logging
- [ ] Health checks implemented
- [ ] Metrics collection
- [ ] Retry logic for external calls
- [ ] Graceful shutdown handling

## Python Tools

- **black**: Code formatter
- **flake8**: Linter
- **pylint**: Code analysis
- **mypy**: Type checker
- **bandit**: Security scanner
- **pytest**: Testing framework
- **coverage**: Code coverage
