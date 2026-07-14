import 'package:flutter/material.dart';

import '../../../../core/constants/strings_es.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(StringsEs.legalTerminosTitulo),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: const [
          _Section(
            title: '1. Qué es PostulaAI',
            body:
                'PostulaAI es una aplicación móvil que usa inteligencia artificial '
                'para ayudar a usuarios en Argentina a evaluar ofertas laborales, '
                'generar CVs personalizados y prepararse para entrevistas de trabajo.\n\n'
                'Al usar la app aceptás estos términos. Si no estás de acuerdo, '
                'no uses el servicio.',
          ),
          _Section(
            title:
                '2. Los resultados de la IA son sugerencias',
            body:
                'PostulaAI usa IA generativa (Google Gemini) para producir '
                'evaluaciones de ofertas, CVs y preguntas de entrevista. '
                'Estos resultados son sugerencias basadas en la información de tu '
                'perfil y no constituyen asesoramiento profesional, legal ni '
                'laboral.\n\n'
                'PostulaAI no garantiza que obtendrás empleo como resultado del '
                'uso de la app, ni que los contenidos generados sean exactos, '
                'completos o adecuados para todas las situaciones.',
          ),
          _Section(
            title: '3. Plan gratuito y plan premium',
            body:
                'Plan gratuito: incluye 3 evaluaciones, 1 CV generado y 3 sesiones '
                'de coach por día. Los contadores se reinician a las 00:00 (hora '
                'Argentina). Los usuarios gratuitos ven publicidad de AdMob.\n\n'
                'Plan premium: acceso ilimitado a todas las funciones de la app, '
                'sin publicidad. El cobro es mensual o anual según el plan '
                'seleccionado y se gestiona a través de Google Play o App Store.',
          ),
          _Section(
            title: '4. Cancelación y reembolsos',
            body:
                'Podés cancelar tu suscripción premium en cualquier momento desde '
                'la configuración de tu cuenta en Google Play o App Store. Al '
                'cancelar, seguís teniendo acceso al plan premium hasta el final '
                'del período pagado.\n\n'
                'Los reembolsos se rigen por las políticas de Google Play y Apple '
                'App Store, no por PostulaAI directamente.',
          ),
          _Section(
            title: '5. Usos prohibidos',
            body:
                'Está prohibido:\n'
                '• Usar la app para actividades ilegales o para engañar a '
                'empleadores con información falsa.\n'
                '• Intentar acceder a datos de otros usuarios.\n'
                '• Revertir, copiar o redistribuir el código o los prompts de IA '
                'de la app.\n'
                '• Usar la app de forma automatizada (bots, scrapers) sin '
                'autorización expresa.',
          ),
          _Section(
            title: '6. Propiedad intelectual',
            body:
                'El código, diseño y prompts de PostulaAI son propiedad del '
                'desarrollador. El contenido que vos generás con la app (tu CV, '
                'evaluaciones) es tuyo.',
          ),
          _Section(
            title: '7. Limitación de responsabilidad',
            body:
                'PostulaAI se provee "tal como está". No nos hacemos responsables '
                'por pérdidas laborales, económicas o de cualquier otro tipo '
                'derivadas del uso o la imposibilidad de usar la app, ni por '
                'errores en los contenidos generados por IA.',
          ),
          _Section(
            title: '8. Cambios a estos términos',
            body:
                'Podemos actualizar estos términos ante cambios en la app o en la '
                'legislación aplicable. Te notificaremos en la app ante cambios '
                'significativos. Seguir usando la app después de los cambios '
                'implica aceptar los nuevos términos.',
          ),
          _Section(
            title: '9. Contacto',
            body:
                'Para cualquier consulta sobre estos términos:\n'
                'postulaai.app@gmail.com',
          ),
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Última actualización: julio de 2026',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
