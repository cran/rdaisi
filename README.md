# rdaisi

R Client for the [Daisi Platform](https://www.daisi.io/)

## Simple Steps for Using `rdaisi`

1. Install the `rdaisi` R Client:

```r
install.packages("rdaisi")
```

2. Configure your `rdaisi` R Client, setting the path to your Python installation as needed:

```r
configure_daisi(python_path = "/usr/local/bin/python3", daisi_instance = "app")
```

3. Connect to a Daisi:

```r
d <- Daisi("Add Two Numbers")
```

4. Execute a Daisi!

```r
de <- DaisiExecution(d, list(firstNumber = 5, secondNumber = 6))
de$value()
```
