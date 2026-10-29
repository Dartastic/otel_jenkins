// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_jenkins/otel_jenkins.dart';

/// Traces Jenkins calls with OpenTelemetry.
///
/// `otel_jenkins` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Jenkins call in
/// [tracedJenkins]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'jenkins-example');

  // Wraps a Jenkins REST call (job.build, job.config, queue.cancel, etc.) in a CLIENT span.
  final jenkinsId = await tracedJenkins<String>(
    resource: 'Order',
    action: 'example',
    jobName: 'example',
    buildNumber: 1,
    controllerUrl: 'https://api.example.com/v1/resource',
    invoke: () async {
      // Make the Jenkins call here, then report what it returned.
      return 'jenkins_8f3a2c';
    },
  );
  OTelLog.info('tracedJenkins job.build returned $jenkinsId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutJenkinsInstrumentationAsync.
  await runWithoutJenkinsInstrumentationAsync(
    () => tracedJenkins<String>(
      resource: 'Order',
      action: 'example',
      jobName: 'example',
      buildNumber: 1,
      controllerUrl: 'https://api.example.com/v1/resource',
      invoke: () async {
        return 'jenkins_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
