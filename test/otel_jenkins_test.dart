// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_jenkins/otel_jenkins.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_jenkins-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('job.build records CLIENT span', () async {
    await tracedJenkins<String>(
      resource: 'job',
      action: 'build',
      jobName: 'app-deploy',
      buildNumber: 42,
      controllerUrl: 'https://ci.acme.com',
      invoke: () async => 'queued',
    );
    final a = attrsOf(spans.findSpanByName('jenkins job.build')!);
    expect(a['cicd.system'], 'jenkins');
    expect(a['jenkins.job.name'], 'app-deploy');
    expect(a['jenkins.build.number'], 42);
    expect(a['jenkins.controller.url'], 'https://ci.acme.com');
  });

  test('suppression skips spans', () async {
    await runWithoutJenkinsInstrumentationAsync(() async {
      await tracedJenkins<String>(
        resource: 'job',
        action: 'build',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('jenkins '), isEmpty);
  });
}
