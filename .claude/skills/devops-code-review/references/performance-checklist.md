# Performance Optimization Checklist for DevOps Code

## Critical Performance Issues

### 1. Resource Leaks

**File Descriptors:**
```bash
# BAD - File descriptor leak
while read line; do
    cat large_file.txt | grep "$line"  # Opens file repeatedly
done < input.txt

# GOOD - Open file once
while read line; do
    grep "$line" large_file.txt
done < input.txt
```

**Python:**
```python
# BAD - Resource leak
def process_files(files):
    for f in files:
        fh = open(f)
        data = fh.read()  # File never closed
        process(data)

# GOOD - Use context manager
def process_files(files):
    for f in files:
        with open(f) as fh:
            data = fh.read()
            process(data)
```

**Go:**
```go
// BAD - Resource leak
func processFiles(files []string) {
    for _, f := range files {
        file, _ := os.Open(f)
        data, _ := io.ReadAll(file)
        // file never closed
        process(data)
    }
}

// GOOD - Defer close
func processFiles(files []string) error {
    for _, f := range files {
        file, err := os.Open(f)
        if err != nil {
            return err
        }
        defer file.Close()

        data, err := io.ReadAll(file)
        if err != nil {
            return err
        }
        process(data)
    }
    return nil
}
```

### 2. Inefficient Loops and Algorithms

**Shell:**
```bash
# BAD - O(n²) complexity
for file in *.log; do
    for pattern in $(cat patterns.txt); do
        grep "$pattern" "$file"  # Reads file multiple times
    done
done

# GOOD - O(n) complexity
grep -f patterns.txt *.log  # Single pass
```

**Python:**
```python
# BAD - Repeated string concatenation O(n²)
result = ""
for item in large_list:
    result += str(item) + "\n"  # Creates new string each time

# GOOD - Use join O(n)
result = "\n".join(str(item) for item in large_list)

# BAD - Inefficient search
for item in large_list:
    if item in another_large_list:  # O(n²)
        process(item)

# GOOD - Use set for O(1) lookup
another_set = set(another_large_list)
for item in large_list:
    if item in another_set:  # O(n)
        process(item)
```

### 3. Unnecessary Process Spawning

**Shell:**
```bash
# BAD - Spawns process for each line
while read line; do
    echo "$line" | awk '{print $1}'  # Spawns awk for each line
done < file.txt

# GOOD - Single awk process
awk '{print $1}' file.txt

# BAD - Multiple greps
grep "pattern1" file.txt
grep "pattern2" file.txt
grep "pattern3" file.txt

# GOOD - Single grep with multiple patterns
grep -E "pattern1|pattern2|pattern3" file.txt
```

### 4. Blocking I/O Operations

**Python:**
```python
# BAD - Sequential blocking I/O
import requests

def fetch_urls(urls):
    results = []
    for url in urls:
        response = requests.get(url)  # Blocks for each request
        results.append(response.text)
    return results

# GOOD - Concurrent I/O
import asyncio
import aiohttp

async def fetch_urls(urls):
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_one(session, url) for url in urls]
        return await asyncio.gather(*tasks)

async def fetch_one(session, url):
    async with session.get(url) as response:
        return await response.text()
```

**Go:**
```go
// BAD - Sequential blocking
func fetchURLs(urls []string) []string {
    var results []string
    for _, url := range urls {
        resp, _ := http.Get(url)  // Blocks
        body, _ := io.ReadAll(resp.Body)
        results = append(results, string(body))
        resp.Body.Close()
    }
    return results
}

// GOOD - Concurrent with goroutines
func fetchURLs(urls []string) []string {
    results := make([]string, len(urls))
    var wg sync.WaitGroup

    for i, url := range urls {
        wg.Add(1)
        go func(i int, url string) {
            defer wg.Done()
            resp, _ := http.Get(url)
            defer resp.Body.Close()
            body, _ := io.ReadAll(resp.Body)
            results[i] = string(body)
        }(i, url)
    }

    wg.Wait()
    return results
}
```

## High Priority Performance Issues

### 5. Memory Inefficiency

**Python:**
```python
# BAD - Loads entire file into memory
with open('huge_file.log') as f:
    lines = f.readlines()  # Loads all lines
    for line in lines:
        process(line)

# GOOD - Stream processing
with open('huge_file.log') as f:
    for line in f:  # Reads line by line
        process(line)

# BAD - Creates unnecessary copies
data = large_list[:]  # Full copy
filtered = [x for x in data if condition(x)]

# GOOD - Use generators
filtered = (x for x in large_list if condition(x))
```

**Go:**
```go
// BAD - Loads entire file
func processFile(filename string) error {
    data, err := os.ReadFile(filename)  // Loads all into memory
    if err != nil {
        return err
    }
    lines := strings.Split(string(data), "\n")
    for _, line := range lines {
        process(line)
    }
    return nil
}

// GOOD - Stream processing
func processFile(filename string) error {
    file, err := os.Open(filename)
    if err != nil {
        return err
    }
    defer file.Close()

    scanner := bufio.NewScanner(file)
    for scanner.Scan() {
        process(scanner.Text())
    }
    return scanner.Err()
}
```

### 6. Inefficient Data Structures

**Python:**
```python
# BAD - List for membership testing
allowed_ips = ['1.2.3.4', '5.6.7.8', ...]  # List
if request_ip in allowed_ips:  # O(n) lookup
    allow()

# GOOD - Set for membership testing
allowed_ips = {'1.2.3.4', '5.6.7.8', ...}  # Set
if request_ip in allowed_ips:  # O(1) lookup
    allow()

# BAD - Repeated dictionary lookups
for key in data:
    if key in config:
        value = config[key]  # Lookup twice
        process(value)

# GOOD - Single lookup
for key in data:
    value = config.get(key)
    if value is not None:
        process(value)
```

### 7. Unnecessary Computations

**Shell:**
```bash
# BAD - Repeated computation in loop
for file in *.txt; do
    count=$(wc -l < "$file")  # Computed but not used efficiently
    if [ $count -gt 100 ]; then
        process_large "$file"
    fi
done

# GOOD - Compute once, use multiple times
for file in *.txt; do
    if [ $(wc -l < "$file") -gt 100 ]; then
        process_large "$file"
    fi
done

# BAD - Redundant operations
cat file.txt | grep pattern | grep another  # Two greps

# GOOD - Combined pattern
grep -E "pattern.*another|another.*pattern" file.txt
```

### 8. Database Query Optimization

**Python:**
```python
# BAD - N+1 query problem
users = User.query.all()
for user in users:
    orders = Order.query.filter_by(user_id=user.id).all()  # N queries
    process(user, orders)

# GOOD - Join or eager loading
users = User.query.options(joinedload(User.orders)).all()
for user in users:
    process(user, user.orders)

# BAD - Fetching unnecessary columns
results = db.execute("SELECT * FROM large_table WHERE id = ?", (id,))

# GOOD - Select only needed columns
results = db.execute("SELECT id, name, status FROM large_table WHERE id = ?", (id,))
```

### 9. Network Optimization

**Python:**
```python
# BAD - No connection pooling
for i in range(1000):
    conn = http.client.HTTPConnection('api.example.com')
    conn.request('GET', '/data')
    response = conn.getresponse()
    conn.close()

# GOOD - Use session with connection pooling
import requests
session = requests.Session()
for i in range(1000):
    response = session.get('http://api.example.com/data')

# BAD - No timeout
response = requests.get(url)  # Can hang forever

# GOOD - Set timeout
response = requests.get(url, timeout=30)
```

### 10. Caching Strategies

**Python:**
```python
# BAD - Repeated expensive computation
def get_config():
    with open('config.yaml') as f:
        return yaml.safe_load(f)  # Reads file every time

for i in range(1000):
    config = get_config()
    process(config)

# GOOD - Cache result
from functools import lru_cache

@lru_cache(maxsize=1)
def get_config():
    with open('config.yaml') as f:
        return yaml.safe_load(f)

for i in range(1000):
    config = get_config()  # Cached after first call
    process(config)
```

## Medium Priority Performance Issues

### 11. Logging Performance

```python
# BAD - String formatting always executed
logger.debug("Processing item: " + str(complex_object))  # Formatted even if debug disabled

# GOOD - Lazy evaluation
logger.debug("Processing item: %s", complex_object)  # Only formatted if debug enabled

# BAD - Excessive logging in hot path
for item in millions_of_items:
    logger.info(f"Processing {item}")  # Too much logging

# GOOD - Sample logging
for i, item in enumerate(millions_of_items):
    if i % 1000 == 0:
        logger.info(f"Processed {i} items")
```

### 12. Regular Expression Optimization

**Python:**
```python
# BAD - Compile regex in loop
for line in lines:
    if re.match(r'\d{3}-\d{3}-\d{4}', line):  # Compiles each time
        process(line)

# GOOD - Compile once
phone_pattern = re.compile(r'\d{3}-\d{3}-\d{4}')
for line in lines:
    if phone_pattern.match(line):
        process(line)
```

### 13. Parallel Processing

**Shell:**
```bash
# BAD - Sequential processing
for file in *.log; do
    process_log "$file"
done

# GOOD - Parallel processing
for file in *.log; do
    process_log "$file" &
done
wait

# BETTER - Controlled parallelism with GNU parallel
parallel process_log ::: *.log

# Or with xargs
ls *.log | xargs -P 4 -I {} process_log {}
```

**Python:**
```python
# BAD - Sequential CPU-bound work
results = [expensive_computation(x) for x in data]

# GOOD - Parallel processing
from multiprocessing import Pool

with Pool() as pool:
    results = pool.map(expensive_computation, data)
```

## Performance Review Checklist

### Resource Management
- [ ] No file descriptor leaks
- [ ] Proper connection pooling
- [ ] Memory usage is bounded
- [ ] Resources are properly closed/released

### Algorithm Efficiency
- [ ] No O(n²) or worse algorithms where O(n) or O(n log n) is possible
- [ ] Appropriate data structures used
- [ ] No unnecessary computations in loops
- [ ] Efficient search and lookup operations

### I/O Optimization
- [ ] Batch operations where possible
- [ ] Streaming for large files
- [ ] Async I/O for network operations
- [ ] Minimal disk I/O

### Concurrency
- [ ] Parallel processing for independent tasks
- [ ] Proper use of async/await
- [ ] No blocking operations in hot paths
- [ ] Thread-safe operations

### Caching
- [ ] Expensive operations are cached
- [ ] Cache invalidation strategy exists
- [ ] Appropriate cache size limits

### Database
- [ ] No N+1 query problems
- [ ] Proper indexing
- [ ] Connection pooling
- [ ] Query result pagination

### Network
- [ ] Connection reuse
- [ ] Timeouts configured
- [ ] Retry logic with backoff
- [ ] Compression enabled where appropriate

## DevOps-Specific Performance Considerations

### Monitoring and Metrics Collection
- Use sampling for high-frequency metrics
- Batch metric submissions
- Async metric collection
- Local aggregation before sending

### Log Processing
- Stream processing for large logs
- Use appropriate log levels
- Structured logging for efficient parsing
- Log rotation and compression

### Container Performance
- Multi-stage builds to reduce image size
- Minimize layers
- Use appropriate base images
- Resource limits configured

### CI/CD Pipeline
- Parallel job execution
- Caching dependencies
- Incremental builds
- Artifact reuse

### Infrastructure Automation
- Parallel resource provisioning
- Idempotent operations
- State management optimization
- API rate limit handling
