import 'package:flutter/material.dart';

import '../../../../core/constants/strings_es.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(StringsEs.legalPrivacidadTitulo)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: const [
          _Section(
            title: '1. Qué datos recopilamos',
            body:
                'PostulaAI recopila la información que vos proporcionás durante '
                'el registro y el onboarding:\n\n'
                '• Datos de perfil: nombre, email, teléfono, ciudad, experiencia '
                'laboral, educación, certificaciones, habilidades, idiomas y '
                'preferencias laborales.\n'
                '• Contenido generado: evaluaciones de ofertas, CVs personalizados '
                'y sesiones de coach de entrevistas.\n'
                '• Datos de uso: contadores diarios de evaluaciones, CVs generados '
                'y sesiones de coach, almacenados para aplicar los límites del plan '
                'gratuito.\n'
                '• Información de autenticación: provista por Google Sign-In. '
                'No almacenamos contraseñas.',
          ),
          _Section(
            title: '2. Cómo usamos tus datos',
            body:
                'Los datos de tu perfil se envían a Google Gemini (vía Firebase '
                'Cloud Functions) para generar evaluaciones de ofertas, CVs '
                'personalizados y preguntas de entrevista. No compartimos tus '
                'datos con terceros con fines comerciales ni publicitarios.\n\n'
                'Tus CVs y evaluaciones se almacenan en Firestore exclusivamente '
                'para que puedas acceder a ellos desde la app. No los usamos para '
                'entrenar modelos de IA.',
          ),
          _Section(
            title: '3. Terceros que intervienen',
            body:
                '• Firebase / Google: autenticación (Firebase Auth), base de datos '
                '(Firestore) y funciones de backend (Cloud Functions). '
                'Política de privacidad: policies.google.com/privacy\n'
                '• Google Gemini: procesamiento de IA para generación de '
                'evaluaciones y CVs.\n'
                '• RevenueCat: gestión de suscripciones y compras in-app.\n'
                '• Google AdMob: publicidad mostrada exclusivamente a usuarios '
                'del plan gratuito.',
          ),
          _Section(
            title: '4. Seguridad',
            body:
                'El acceso a tus datos en Firestore está protegido por reglas de '
                'seguridad que garantizan que solo vos podés leer y modificar tu '
                'información. Toda la comunicación con los servidores usa HTTPS.',
          ),
          _Section(
            title: '5. Tus derechos',
            body:
                '• Acceso: podés ver todos tus datos en la pantalla de Perfil.\n'
                '• Eliminación: podés solicitar la eliminación de tu cuenta y todos '
                'tus datos escribiendo a postulaai.app@gmail.com. Procesamos la '
                'solicitud en un plazo de 30 días.\n'
                '• Exportación: podés solicitar una copia de tus datos al mismo '
                'email.',
          ),
          _Section(
            title: '6. Retención de datos',
            body:
                'Guardamos tus datos mientras tu cuenta esté activa. Si eliminás '
                'la cuenta, borramos todos los datos asociados de nuestros sistemas '
                'en un plazo de 30 días.',
          ),
          _Section(
            title: '7. Cambios a esta política',
            body:
                'Podemos actualizar esta política de privacidad ante cambios en la '
                'app o en la legislación aplicable. Te avisaremos en la app ante '
                'cambios significativos.',
          ),
          _Section(
            title: '8. Contacto',
            body:
                'Si tenés preguntas sobre esta política o querés ejercer tus '
                'derechos, escribinos a:\npostulaai.app@gmail.com',
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
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
