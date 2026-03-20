# Kram's Lessons: Integral Calculus

This document rewrites the integral calculus lesson content using professional LaTeX notation for formulas, theorems, and worked examples.

---

## 24. Indefinite Integrals

Indefinite integrals represent antiderivatives, or primitive functions. If $F$ is an antiderivative of $f$, then

$$
\int f(x)\,dx = F(x) + C
$$

with

$$
\frac{d}{dx}F(x) = f(x),
$$

where $C$ is an arbitrary constant of integration.

### 24.0 Primitive Functions

A primitive, or antiderivative, of a function $f$ is a function $F$ such that

$$
\frac{d}{dx}F(x) = f(x)
$$

for every $x$ in the domain. Differentiation and integration undo each other, so

$$
\int f(x)\,dx = F(x) + C.
$$

If $F$ is one primitive of $f$, then every primitive has the form

$$
F(x) + C.
$$

**Example**

Since

$$
\frac{d}{dx}\left(x^2\right) = 2x,
$$

we obtain

$$
\int 2x\,dx = x^2 + C.
$$

### 24.1 Immediate Integration Rules

The main basic rules are:

$$
\int x^n\,dx = \frac{x^{n+1}}{n+1} + C, \qquad n \neq -1
$$

$$
\int \frac{1}{x}\,dx = \ln|x| + C
$$

$$
\int e^x\,dx = e^x + C
$$

$$
\int \cos x\,dx = \sin x + C
$$

$$
\int \sin x\,dx = -\cos x + C
$$

and linearity gives

$$
\int \left(af(x) + bg(x)\right)\,dx = a\int f(x)\,dx + b\int g(x)\,dx.
$$

**Example**

$$
\int \left(3x^2 + 2x + 1\right)\,dx
= 3\int x^2\,dx + 2\int x\,dx + \int 1\,dx
= 3\cdot \frac{x^3}{3} + 2\cdot \frac{x^2}{2} + x + C
= x^3 + x^2 + x + C.
$$

---

## 25. Integration Methods

When an integrand is not handled directly by the basic rules, two standard techniques are substitution and integration by parts.

### 25.0 Integration by Substitution

Substitution is the reverse of the chain rule. If we set

$$
u = g(x),
\qquad
du = g'(x)\,dx,
$$

then

$$
\int f\!\left(g(x)\right)g'(x)\,dx = \int f(u)\,du.
$$

After integrating with respect to $u$, we substitute back $u = g(x)$.

**Example**

Let

$$
u = x^2,
\qquad
du = 2x\,dx.
$$

Then

$$
\int 2x\,e^{x^2}\,dx
= \int e^u\,du
= e^u + C
= e^{x^2} + C.
$$

### 25.1 Integration by Parts

Integration by parts comes from the product rule:

$$
\frac{d}{dx}\left(u(x)v(x)\right) = u'(x)v(x) + u(x)v'(x).
$$

Rearranging and integrating gives

$$
\int u\,dv = uv - \int v\,du.
$$

**Example**

Choose

$$
u = x,
\qquad
du = dx,
\qquad
dv = e^x\,dx,
\qquad
v = e^x.
$$

Then

$$
\int x e^x\,dx
= xe^x - \int e^x\,dx
= xe^x - e^x + C
= e^x(x - 1) + C.
$$

---

## 26. Definite Integrals

The definite integral

$$
\int_a^b f(x)\,dx
$$

represents the signed area between the graph of $y=f(x)$ and the $x$-axis on the interval $[a,b]$. If $f(x)\ge 0$ on $[a,b]$, then this integral equals the geometric area under the curve.

If $F$ is an antiderivative of $f$, then

$$
\int_a^b f(x)\,dx = F(b) - F(a).
$$

### 26.0 Calculating the Area Under a Curve

The computation of a definite integral is based on the antiderivative and endpoint evaluation:

$$
\int_a^b f(x)\,dx = \left[F(x)\right]_a^b = F(b) - F(a).
$$

**Example**

$$
\int_0^1 x^2\,dx
= \left[\frac{x^3}{3}\right]_0^1
= \frac{1^3}{3} - \frac{0^3}{3}
= \frac{1}{3}.
$$

### 26.1 The Fundamental Theorem of Calculus

The Fundamental Theorem of Calculus has two parts.

**Part 1**

If $f$ is continuous on $[a,b]$ and

$$
F(x) = \int_a^x f(t)\,dt,
$$

then

$$
\frac{d}{dx}F(x) = f(x).
$$

**Part 2**

If $f$ is continuous on $[a,b]$ and $F$ is any antiderivative of $f$, then

$$
\int_a^b f(x)\,dx = F(b) - F(a) = \left[F(x)\right]_a^b.
$$

**Example**

To evaluate

$$
\int_0^2 x\,dx,
$$

take

$$
F(x) = \frac{x^2}{2}.
$$

Then

$$
\int_0^2 x\,dx
= \left[\frac{x^2}{2}\right]_0^2
= \frac{2^2}{2} - \frac{0^2}{2}
= 2.
$$

---

## 27. Applications of Integrals

Definite integrals are used to compute geometric and physical quantities such as areas and volumes.

### 27.0 Calculation of Volumes

For rotation about the $x$-axis, the disk method gives

$$
V = \pi \int_a^b \left(f(x)\right)^2\,dx.
$$

If there is an inner radius $g(x)$ and an outer radius $f(x)$, the washer method gives

$$
V = \pi \int_a^b \left(\left(f(x)\right)^2 - \left(g(x)\right)^2\right)\,dx.
$$

**Example: cone**

If

$$
y = \frac{r}{h}x
$$

for $x \in [0,h]$, then rotating around the $x$-axis produces a cone with volume

$$
V
= \pi \int_0^h \left(\frac{r}{h}x\right)^2\,dx
= \pi \int_0^h \frac{r^2}{h^2}x^2\,dx
= \pi \cdot \frac{r^2}{h^2} \left[\frac{x^3}{3}\right]_0^h
= \frac{1}{3}\pi r^2 h.
$$

### 27.1 Areas of Plane Figures

If $f(x)\ge g(x)$ on $[a,b]$, then the area between the curves $y=f(x)$ and $y=g(x)$ is

$$
A = \int_a^b \left(f(x) - g(x)\right)\,dx.
$$

If the curves intersect, split the interval at the intersection points and compute the area on each subinterval.

**Example**

Between $y=x$ and $y=x^2$ on $[0,1]$, we have $x \ge x^2$, so

$$
A
= \int_0^1 \left(x - x^2\right)\,dx
= \left[\frac{x^2}{2} - \frac{x^3}{3}\right]_0^1
= \left(\frac{1}{2} - \frac{1}{3}\right) - 0
= \frac{1}{6}.
$$
