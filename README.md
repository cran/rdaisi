# rdaisi

R Client for the [Daisi Platform](https://www.daisi.io/)

## Simple Steps for Using `rdaisi`

1. Install the `rdaisi` R Client:

```r
install.packages("rdaisi")
```

2. Configure your `rdaisi` R Client, setting the path to your Python installation as needed:

```r
configure_daisi(python_path = "/usr/local/bin/python3")
```

3. Connect to a Daisi:

```r
d <- Daisi("Add Two Numbers")
```

4. Execute a Daisi!

```r
d$compute(firstNumber = 4, secondNumber = 5)$value()
```
