# Authentication & Authorization Patterns

## Detection Strategy

Scan for route/endpoint definitions, then verify each has authentication applied.

## Framework Patterns

### Express / Koa

```javascript
// PROTECTED — has auth middleware
app.get('/api/users', authMiddleware, handler)
router.use('/admin', requireAuth)

// UNPROTECTED — missing auth
app.get('/api/users', handler)          // No middleware
app.post('/api/orders', createOrder)    // Direct handler
```

**Detection**: Find `app.get/post/put/delete/patch` and `router.*` calls, check if auth middleware is in the chain.

### NestJS

```typescript
// PROTECTED — has guard
@UseGuards(AuthGuard)
@Controller('users')

// UNPROTECTED — explicitly public
@Public()
@Get('admin/dashboard')    // Dangerous: admin route marked public
```

**Detection**: Find `@Controller` and `@Get/@Post/etc` decorators, verify `@UseGuards` or global guard exists. Flag `@Public()` on sensitive paths.

### Django

```python
# PROTECTED
@login_required
def user_profile(request): ...

class OrderView(LoginRequiredMixin, View): ...

# UNPROTECTED
def admin_panel(request): ...    # Missing decorator
```

**Detection**: Find view functions/classes, check for `@login_required`, `LoginRequiredMixin`, `@permission_required`, or `IsAuthenticated` in DRF.

### Spring Boot

```java
// SecurityFilterChain configuration
http.authorizeHttpRequests(auth -> auth
    .requestMatchers("/api/public/**").permitAll()
    .requestMatchers("/api/admin/**").hasRole("ADMIN")
    .anyRequest().authenticated()
);

// DANGEROUS: overly permissive
.anyRequest().permitAll()
```

**Detection**: Find `SecurityFilterChain` or `WebSecurityConfigurerAdapter`, check for `.permitAll()` on sensitive paths and `.anyRequest().permitAll()`.

### Rails

```ruby
# PROTECTED
class AdminController < ApplicationController
  before_action :authenticate_user!

# GAP — skipping auth
class PaymentController < ApplicationController
  skip_before_action :authenticate_user!, only: [:webhook]
  # Is this webhook properly secured with signature verification?
```

**Detection**: Check `before_action` chain in controllers, flag `skip_before_action` on sensitive operations.

### FastAPI

```python
# PROTECTED
@app.get("/users/me")
async def read_users_me(current_user: User = Depends(get_current_user)):

# UNPROTECTED
@app.get("/admin/stats")
async def admin_stats():    # No Depends() for auth
```

**Detection**: Find route decorators, check for `Depends(get_current_user)` or similar auth dependency.

## Common Gaps

1. **New routes without auth** — Developer adds endpoint, forgets middleware
2. **Webhook endpoints** — Intentionally public but need signature verification
3. **Admin routes** — Higher privilege but sometimes lower protection
4. **File upload endpoints** — Often missing both auth and validation
5. **GraphQL** — Single endpoint, auth must be per-resolver
