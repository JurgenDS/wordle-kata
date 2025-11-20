package com.example.hello.architecture;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("Loose Coupling Tests")
class LooseCouplingTest {

    private static final Pattern HARDCODED_URL_PATTERN =
        Pattern.compile("(\"https?://(?:localhost|127\\.0\\.0\\.1):\\d+[^\"]*\")");

    private static final Path SOURCE_ROOT = Paths.get("src/main/java");

    @Test
    @DisplayName("Should not contain hardcoded URLs in source code")
    void shouldNotContainHardcodedUrls() throws IOException {
        List<String> violations = new ArrayList<>();

        try (Stream<Path> paths = Files.walk(SOURCE_ROOT)) {
            paths.filter(Files::isRegularFile)
                 .filter(path -> path.toString().endsWith(".java"))
                 .forEach(path -> checkFileForHardcodedUrls(path, violations));
        }

        assertThat(violations)
            .withFailMessage(() -> buildViolationMessage(violations))
            .isEmpty();
    }

    private void checkFileForHardcodedUrls(Path file, List<String> violations) {
        try {
            List<String> lines = Files.readAllLines(file);
            for (int i = 0; i < lines.size(); i++) {
                String line = lines.get(i);
                Matcher matcher = HARDCODED_URL_PATTERN.matcher(line);
                if (matcher.find()) {
                    violations.add(String.format(
                        "%s:%d - Found hardcoded URL: %s",
                        SOURCE_ROOT.relativize(file),
                        i + 1,
                        matcher.group(1)
                    ));
                }
            }
        } catch (IOException e) {
            violations.add(String.format("Error reading file %s: %s", file, e.getMessage()));
        }
    }

    private String buildViolationMessage(List<String> violations) {
        StringBuilder message = new StringBuilder();
        message.append("\n\n");
        message.append("==========================================\n");
        message.append("LOOSE COUPLING VIOLATION DETECTED\n");
        message.append("==========================================\n\n");
        message.append("Found ").append(violations.size()).append(" hardcoded URL(s) in source code:\n\n");

        violations.forEach(violation -> message.append("  ❌ ").append(violation).append("\n"));

        message.append("\n");
        message.append("💡 How to fix:\n");
        message.append("  1. Move URL to src/main/resources/application.yml:\n");
        message.append("     my.service.url: ${MY_SERVICE_URL:http://localhost:8080}\n\n");
        message.append("  2. Inject using @Value annotation:\n");
        message.append("     @Value(\"${my.service.url}\")\n");
        message.append("     private String serviceUrl;\n\n");
        message.append("  3. This maintains loose coupling and allows environment-specific configuration.\n");
        message.append("\n==========================================\n");

        return message.toString();
    }
}
