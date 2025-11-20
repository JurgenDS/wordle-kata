package com.example.hello.architecture;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.lang.ArchRule;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.Architectures.layeredArchitecture;

@DisplayName("Hexagonal Architecture Tests")
class HexagonalArchitectureTest {

    private static JavaClasses importedClasses;

    @BeforeAll
    static void setup() {
        importedClasses = new ClassFileImporter()
                .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
                .importPackages("com.example.hello");
    }

    @Test
    @DisplayName("Domain layer should not depend on application layer")
    void domainShouldNotDependOnApplication() {
        ArchRule rule = noClasses()
                .that().resideInAPackage("..domain..")
                .should().dependOnClassesThat()
                .resideInAPackage("..application..");

        rule.check(importedClasses);
    }

    @Test
    @DisplayName("Domain layer should not depend on adapter layer")
    void domainShouldNotDependOnAdapters() {
        ArchRule rule = noClasses()
                .that().resideInAPackage("..domain..")
                .should().dependOnClassesThat()
                .resideInAPackage("..adapter..");

        rule.check(importedClasses);
    }

    @Test
    @DisplayName("Domain layer should not depend on Spring framework")
    void domainShouldNotDependOnSpringFramework() {
        ArchRule rule = noClasses()
                .that().resideInAPackage("..domain..")
                .should().dependOnClassesThat()
                .resideInAPackage("org.springframework..");

        rule.check(importedClasses);
    }

    @Test
    @DisplayName("Application layer should not depend on adapter layer")
    void applicationShouldNotDependOnAdapters() {
        ArchRule rule = noClasses()
                .that().resideInAPackage("..application..")
                .should().dependOnClassesThat()
                .resideInAPackage("..adapter..");

        rule.check(importedClasses);
    }

    @Test
    @DisplayName("Adapters can depend on application and domain layers")
    void adaptersMayDependOnApplicationAndDomain() {
        ArchRule rule = classes()
                .that().resideInAPackage("..adapter..")
                .should().onlyDependOnClassesThat()
                .resideInAnyPackage(
                        "..adapter..",
                        "..application..",
                        "..domain..",
                        "java..",
                        "org.springframework..",
                        "io.vavr..",
                        "lombok.."
                );

        rule.check(importedClasses);
    }

    @Test
    @DisplayName("Hexagonal architecture layers should be respected")
    void layersShouldBeRespected() {
        layeredArchitecture()
                .consideringAllDependencies()
                .layer("Adapters").definedBy("..adapter..")
                .layer("Application").definedBy("..application..")
                .layer("Domain").definedBy("..domain..")
                .whereLayer("Adapters").mayNotBeAccessedByAnyLayer()
                .whereLayer("Application").mayOnlyBeAccessedByLayers("Adapters")
                .whereLayer("Domain").mayOnlyBeAccessedByLayers("Application", "Adapters")
                .check(importedClasses);
    }

    @Test
    @DisplayName("Controllers should be in adapter.incoming.rest package")
    void controllersShouldBeInCorrectPackage() {
        ArchRule rule = classes()
                .that().haveSimpleNameEndingWith("Controller")
                .should().resideInAPackage("..adapter.incoming.rest..");

        rule.check(importedClasses);
    }

    @Test
    @DisplayName("Commands should be in application package")
    void commandsShouldBeInApplicationPackage() {
        ArchRule rule = classes()
                .that().haveSimpleNameEndingWith("Command")
                .should().resideInAPackage("..application..");

        rule.check(importedClasses);
    }

    @Test
    @DisplayName("Domain classes should not have Spring annotations")
    void domainShouldNotHaveSpringAnnotations() {
        ArchRule rule = noClasses()
                .that().resideInAPackage("..domain..")
                .should().beAnnotatedWith("org.springframework.stereotype.Component")
                .orShould().beAnnotatedWith("org.springframework.stereotype.Service")
                .orShould().beAnnotatedWith("org.springframework.stereotype.Repository")
                .orShould().beAnnotatedWith("org.springframework.web.bind.annotation.RestController");

        rule.check(importedClasses);
    }

    @Test
    @DisplayName("REST Controllers should have @RestController annotation")
    void restControllersShouldBeAnnotated() {
        ArchRule rule = classes()
                .that().resideInAPackage("..adapter.incoming.rest..")
                .and().haveSimpleNameEndingWith("Controller")
                .should().beAnnotatedWith("org.springframework.web.bind.annotation.RestController");

        rule.check(importedClasses);
    }

    @Test
    @DisplayName("Processors should be in application package")
    void processorsShouldBeInApplicationPackage() {
        ArchRule rule = classes()
                .that().haveSimpleNameEndingWith("Processor")
                .should().resideInAPackage("..application..");

        rule.check(importedClasses);
    }

    @Test
    @DisplayName("Domain response objects should be in domain package")
    void responseShouldBeInDomainPackage() {
        ArchRule rule = classes()
                .that().haveSimpleNameEndingWith("Response")
                .should().resideInAPackage("..domain..")
                .allowEmptyShould(true);

        rule.check(importedClasses);
    }

    @Test
    @DisplayName("Should not contain hardcoded URLs (loose coupling)")
    void shouldNotContainHardcodedUrls() {
        ArchRule rule = noClasses()
                .that().resideInAPackage("..com.example.hello..")
                .should().accessClassesThat().haveSimpleNameContaining("HttpUrl")
                .orShould().accessClassesThat().haveSimpleNameContaining("localhost")
                .because("URLs should be externalized via configuration files (application.yml) " +
                        "to maintain loose coupling between components. " +
                        "Use @Value(\"${property}\") or environment configuration instead.");

        rule.check(importedClasses);
    }
}
