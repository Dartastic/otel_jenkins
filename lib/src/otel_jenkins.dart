// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_jenkins_suppression.dart';

const _tracerName = 'dartastic_otel_libs_jenkins';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a Jenkins REST call (`job.build`, `job.config`,
/// `queue.cancel`, etc.) in a CLIENT span.
Future<T> tracedJenkins<T>({
  required String resource,
  required String action,
  required Future<T> Function() invoke,
  String? jobName,
  int? buildNumber,
  String? controllerUrl,
}) async {
  if (jenkinsInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'cicd.system': 'jenkins',
    'jenkins.resource': resource,
    'jenkins.action': action,
    'jenkins.operation': '$resource.$action',
  };
  if (jobName != null) m['jenkins.job.name'] = jobName;
  if (buildNumber != null) m['jenkins.build.number'] = buildNumber;
  if (controllerUrl != null) m['jenkins.controller.url'] = controllerUrl;

  final span = _tracer().startSpan(
    'jenkins $resource.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
