figma.showUI(__html__, { width: 320, height: 520 });

// A map to store image data to handle '#' tag for asset reuse
const imageAssetMap = new Map<string, Uint8Array>();

figma.ui.onmessage = async (msg) => {
  if (msg.type === 'export') {
    imageAssetMap.clear();

    const selection = figma.currentPage.selection;

    if (selection.length === 0) {
      figma.notify("Please select at least one frame or component.");
      figma.ui.postMessage({ type: 'export-result', mappingString: '', images: [] });
      return;
    }

    const mapping = [];
    for (const node of selection) {
      // Pass the map to be populated by the recursive function
      mapping.push(await processNode(node, imageAssetMap));
    }

    const mappingString = JSON.stringify(mapping, null, 2);

    // Convert map to array of objects for postMessage
    const images = Array.from(imageAssetMap.entries()).map(([id, bytes]) => ({ id, bytes }));

    figma.ui.postMessage({ type: 'export-result', mappingString: mappingString, images: images });
  }
};

async function processNode(node: SceneNode, assetMap: Map<string, Uint8Array>): Promise<any> {
  const tags = parseTags(node.name);
  const assetId = parseAssetId(node.name);

  const nodeData: any = {
    id: node.id,
    name: node.name,
    type: node.type,
    tags: tags,
    properties: getNodeProperties(node),
    children: [],
    assetId: null,
  };

  const isExportable = tags.includes('image') || tags.includes('button') || tags.includes('parent');

  if (assetId) {
    nodeData.assetId = assetId;
    // If this assetId has not been exported yet, export it now
    if (isExportable && !assetMap.has(assetId)) {
      const imageBytes = await node.exportAsync({ format: 'PNG', constraint: { type: 'SCALE', value: 2 } });
      assetMap.set(assetId, imageBytes);
    }
  } else if (isExportable) {
    // Auto-generate an asset ID if it's exportable but has no #tag
    const autoAssetId = `asset_${node.id.replace(/:/g, '_')}`;
    nodeData.assetId = autoAssetId;
    if (!assetMap.has(autoAssetId)) {
        const imageBytes = await node.exportAsync({ format: 'PNG', constraint: { type: 'SCALE', value: 2 } });
        assetMap.set(autoAssetId, imageBytes);
    }
  }

  // If this node was exported as a parent, don't process its children individually
  if (tags.includes('parent')) {
    return nodeData;
  }

  if ('children' in node) {
    for (const child of node.children) {
      nodeData.children.push(await processNode(child, assetMap));
    }
  }

  return nodeData;
}

function parseTags(name: string): string[] {
    const nameWithoutId = name.split('#')[0];
    return nameWithoutId.split('_').slice(1).filter(t => t);
}

function parseAssetId(name: string): string | null {
    const match = name.match(/#(\w+)/);
    return match ? match[1] : null;
}

function getNodeProperties(node: SceneNode): any {
  const properties: any = {
    size: { x: node.width, y: node.height },
    position: { x: node.x, y: node.y },
    rotation: node.rotation,
    opacity: node.opacity,
    visible: node.visible,
  };

  if ('fills' in node) properties.fills = node.fills;
  if ('strokes' in node) properties.strokes = node.strokes;
  if ('strokeWeight' in node) properties.strokeWeight = node.strokeWeight;
  if ('cornerRadius' in node) properties.cornerRadius = node.cornerRadius;
  if ('constraints' in node) properties.constraints = node.constraints;

  if (node.type === 'TEXT') {
    properties.characters = node.characters;
    properties.fontSize = node.fontSize;
    properties.fontName = node.fontName;
    properties.textAlignHorizontal = node.textAlignHorizontal;
    properties.textAlignVertical = node.textAlignVertical;
    properties.lineHeight = node.lineHeight;
    properties.letterSpacing = node.letterSpacing;
    properties.textCase = node.textCase;
    properties.textDecoration = node.textDecoration;
  }

  return properties;
}
