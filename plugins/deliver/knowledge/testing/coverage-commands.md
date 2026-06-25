# Coverage Commands — Quick Reference

Find the section for your stack. Run the command, then locate the output file.

---

## Python (pytest-cov)

```bash
# Install
pip install pytest-cov

# Run with XML output (Cobertura format — for coverage-loop-agent)
pytest --cov=src --cov-report=xml --cov-report=term-missing tests/

# Output: coverage.xml (in project root)
# Also useful: htmlcov/index.html (human-readable)

# THE DELIVER MANDATE: enforce 100% (fail CI if any line is uncovered)
pytest --cov=src --cov-fail-under=100 tests/

# Legacy threshold (do not use — 90% means 10% of your code is unverified)
# pytest --cov=src --cov-fail-under=90 tests/
```

> **Why 100%?** Every number below 100 is a policy that says "some of our code
> is allowed to be wrong and undetected." 91% coverage means 9% of your code
> has never been executed by a test. That 9% is where the bugs live.
> `--cov-fail-under=100` makes coverage a hard gate: the build fails if any
> production line is uncovered. Add `# pragma: no cover` only for code that
> genuinely cannot be tested (OS-specific branches, legacy shims) and document
> why in the same comment.

---

## JavaScript / TypeScript (Jest)

```bash
# jest.config.js — add coverage config
module.exports = {
  collectCoverage: true,
  coverageReporters: ['cobertura', 'text', 'html'],
  coverageDirectory: 'coverage',
}

# Run
npx jest --coverage

# Output: coverage/cobertura-coverage.xml
```

---

## JavaScript / TypeScript (Vitest)

```bash
# vitest.config.ts
export default {
  test: {
    coverage: {
      reporter: ['cobertura', 'text', 'html'],
      provider: 'v8',
    }
  }
}

# Run
npx vitest run --coverage

# Output: coverage/cobertura-coverage.xml
```

---

## Go

```bash
# Run tests with coverage profile
go test ./... -coverprofile=coverage.out

# Convert to XML (requires gocov tools)
go install github.com/axw/gocov/gocov@latest
go install github.com/AlekSi/gocov-xml@latest
gocov convert coverage.out | gocov-xml > coverage.xml

# Human-readable HTML
go tool cover -html=coverage.out -o coverage.html

# Quick terminal report
go tool cover -func=coverage.out
```

---

## Ruby (SimpleCov)

```ruby
# spec/spec_helper.rb or test/test_helper.rb
require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.start do
  formatter SimpleCov::Formatter::CoberturaFormatter
  add_filter '/spec/'
  add_filter '/test/'
end
```

```bash
bundle exec rspec  # or bundle exec rake test
# Output: coverage/coverage.xml
```

---

## Java (JaCoCo with Maven)

```xml
<!-- pom.xml -->
<plugin>
  <groupId>org.jacoco</groupId>
  <artifactId>jacoco-maven-plugin</artifactId>
  <executions>
    <execution>
      <goals><goal>prepare-agent</goal></goals>
    </execution>
    <execution>
      <id>report</id>
      <phase>test</phase>
      <goals><goal>report</goal></goals>
    </execution>
  </executions>
</plugin>
```

```bash
mvn test
# Output: target/site/jacoco/jacoco.xml
```

---

## Rust (llvm-cov)

```bash
cargo install cargo-llvm-cov

# Run
cargo llvm-cov --cobertura --output-path coverage.xml

# Human-readable
cargo llvm-cov --html
```

---

## C# (.NET)

```bash
dotnet test --collect:"XPlat Code Coverage"
# Output: TestResults/**/*.xml (Cobertura format)

# Or with coverlet
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=cobertura
# Output: coverage.cobertura.xml
```

---

## Parsing coverage.xml (Cobertura format)

The coverage-loop-agent parses Cobertura XML. Key structure:

```xml
<coverage line-rate="0.85" ...>
  <packages>
    <package name="myapp">
      <classes>
        <class filename="myapp/orders.py" line-rate="0.42">
          <lines>
            <line number="47" hits="0"/>  <!-- uncovered -->
            <line number="48" hits="1"/>  <!-- covered -->
          </lines>
        </class>
      </classes>
    </package>
  </packages>
</coverage>
```

`line-rate` = covered / total (0.0 to 1.0). Multiply by 100 for %.
`hits="0"` = uncovered line.
