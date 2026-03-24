import 'dart:convert';
import 'dart:typed_data';

enum AttachmentType { image, file }

class Attachment {
  final String id;
  final AttachmentType type;
  final String name;
  final String mimeType;
  final Uint8List bytes;
  final String? text; // extracted text for files

  const Attachment({
    required this.id,
    required this.type,
    required this.name,
    required this.mimeType,
    required this.bytes,
    this.text,
  });

  String get base64Data => base64Encode(bytes);

  bool get isImage => type == AttachmentType.image;
  bool get isFile => type == AttachmentType.file;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'name': name,
        'mimeType': mimeType,
        'bytes': base64Data,
        'text': text,
      };

  factory Attachment.fromMap(Map<String, dynamic> map) => Attachment(
        id: map['id'] as String,
        type: AttachmentType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => AttachmentType.file,
        ),
        name: map['name'] as String,
        mimeType: map['mimeType'] as String,
        bytes: base64Decode(map['bytes'] as String),
        text: map['text'] as String?,
      );

  // Build OpenAI-compatible image_url content block
  Map<String, dynamic> toOpenAIImageBlock() => {
        'type': 'image_url',
        'image_url': {'url': 'data:$mimeType;base64,$base64Data'},
      };

  // Build Anthropic-compatible image source block
  Map<String, dynamic> toAnthropicImageBlock() => {
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': mimeType,
          'data': base64Data,
        },
      };
}
