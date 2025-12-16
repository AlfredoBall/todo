using System;
using System.Collections.Generic;
using System.Text;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using Todo.Data.Access;
using C = Todo.Data.Entity.Context;
using E = Todo.Data.Entity;

namespace Todo.Data.Service;

public class ClipboardService(IMapper mapper)
{
    public async Task<IList<Clipboard>> GetClipboards(C context)
    {
        return await context.Clipboards
            .Select(i => mapper.Map<Clipboard>(i))
            .ToListAsync();
    }

    public async Task<Clipboard?> AddClipboard(C context, string name)
    {
        if (name.Trim().Length == 0 || await context.Clipboards.AnyAsync(i => i.Name == name))
        {
            return null;
        }

        var entity = new E.Clipboard { Name = name };
        await context.Clipboards.AddAsync(entity);
        await context.SaveChangesAsync();

        var addedEntity = await context.Clipboards
            .AsNoTracking()
            .SingleAsync(i => i.Name == name);

        return mapper.Map<Clipboard>(addedEntity);
    }

    public async Task<bool> DeleteClipboard(C context, int id)
    {
        var entity = await context.Clipboards.FindAsync(id);
        if (entity == null)
        {
            return false;
        }
        context.Clipboards.Remove(entity);
        await context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> EditClipboard(C context, int id, string name)
    {
        if (name.Trim().Length == 0 || await context.Clipboards.AnyAsync(i => i.Name == name))
        {
            return false;
        }

        var entity = await context.Clipboards.FindAsync(id);
        if (entity == null)
        {
            return false;
        }
        entity.Name = name;
        await context.SaveChangesAsync();
        return true;
    }
}
