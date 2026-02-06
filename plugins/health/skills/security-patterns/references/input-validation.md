# Input Validation Patterns

## Detection Strategy

Find where external data enters the system, then verify validation exists before the data is used in sensitive operations.

## Entry Points (External Input Sources)

| Source | Framework Examples |
|--------|-------------------|
| HTTP body | `req.body`, `request.data`, `@RequestBody` |
| URL params | `req.params`, `request.args`, `@PathVariable` |
| Query string | `req.query`, `request.GET`, `@RequestParam` |
| Headers | `req.headers`, `request.META` |
| File uploads | `req.file`, `request.FILES`, `@RequestPart` |
| WebSocket | `socket.on('message')`, `@MessageMapping` |

## Dangerous Operations (Sinks)

### SQL Injection

```javascript
// VULNERABLE — string concatenation
db.query(`SELECT * FROM users WHERE id = ${req.params.id}`)
db.query("SELECT * FROM users WHERE name = '" + name + "'")

// SAFE — parameterized
db.query('SELECT * FROM users WHERE id = $1', [req.params.id])
db.query('SELECT * FROM users WHERE id = ?', [id])
```

**Detection**: Find `query()`, `execute()`, `raw()` calls containing string interpolation (`${}`, `+`, `f"`, `%s`) with user input.

### Cross-Site Scripting (XSS)

```javascript
// VULNERABLE — raw HTML insertion
element.innerHTML = userInput
document.write(data)
res.send(`<div>${req.query.name}</div>`)

// Template engines without escaping
{{ content | safe }}       // Jinja2/Nunjucks
{!! $content !!}           // Blade
dangerouslySetInnerHTML    // React
v-html                     // Vue
```

**Detection**: Find `innerHTML`, `document.write`, `dangerouslySetInnerHTML`, `v-html`, `| safe`, `{!! !!}` with user-controlled data.

### Command Injection

```javascript
// VULNERABLE
exec(`ls ${userInput}`)
os.system(f"convert {filename}")
Runtime.getRuntime().exec("cmd " + input)

// SAFE
execFile('ls', [userInput])    // Array form, no shell
subprocess.run(['convert', filename])  // List form
```

**Detection**: Find `exec()`, `system()`, `spawn()` (with `shell: true`), `popen()` containing string interpolation.

### Path Traversal

```javascript
// VULNERABLE
fs.readFile(`uploads/${req.params.filename}`)
// Attacker: GET /files/../../../etc/passwd

// SAFE
const safePath = path.resolve('uploads', filename)
if (!safePath.startsWith(path.resolve('uploads'))) throw new Error()
```

**Detection**: Find file operations (`readFile`, `readFileSync`, `open()`, `File()`) with user input in path, without path validation.

### NoSQL Injection

```javascript
// VULNERABLE
db.users.find({ username: req.body.username })
// Attacker: { "username": { "$gt": "" } }

// SAFE
db.users.find({ username: String(req.body.username) })
```

**Detection**: Find MongoDB/Mongoose queries where request body fields are passed directly without type coercion.

## Framework Validation Patterns

### Express + Joi/Zod

```javascript
// Validation middleware present?
app.post('/users', validate(schema), handler)
```

### NestJS + class-validator

```typescript
// DTO with decorators?
class CreateUserDto {
  @IsEmail() email: string
  @MinLength(8) password: string
}
```

### Django + DRF Serializers

```python
# Serializer with validation?
class UserSerializer(serializers.Serializer):
    email = serializers.EmailField()
```

### Spring Boot + @Valid

```java
// @Valid annotation present?
public ResponseEntity create(@Valid @RequestBody UserDto dto)
```

## Severity Classification

| Pattern | Severity | Reason |
|---------|----------|--------|
| SQL injection | Critical | Direct data breach |
| Command injection | Critical | Server compromise |
| Hardcoded admin bypass | Critical | Full access |
| XSS (stored) | Critical | Persistent attack |
| Path traversal | Critical | File system access |
| XSS (reflected) | Warning | Requires user click |
| Missing validation on non-sensitive input | Warning | Data quality issue |
| Missing CSRF token | Warning | Action forgery |
